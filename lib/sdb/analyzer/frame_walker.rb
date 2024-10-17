# frozen_string_literal: true

require 'ruby-graphviz'
require 'json'

module Sdb
  module FrameWalker
    class Frame
      attr_writer :parent
      attr_reader :iseq, :children, :duration

      def initialize(iseq, ts)
        @iseq     = iseq
        @ts       = ts
        @duration = 0
        @children = []
        @parent   = nil
      end

      def add_child(frame)
        @children << frame
      end

      def update_ts(new_ts)
        @duration = new_ts - @ts
      end
    end

    class Walker
      def initialize(log_file, iseq_file)
        @log_file = log_file
        @iseq_file = iseq_file
        @methods_table = read_methods
        @roots = []
        @stack = []
      end

      def draw(name)
        graph = GraphViz.new( :G, :type => :digraph )
        graph[:bgcolor] = '#253238'
        @fake_generation = 0
        @total = @roots.map {|root| root.duration }.sum.to_f

        @roots.each do |frame|
          draw_frame(graph, frame)
        end

        graph.output( :png => name )
      end

      def draw_frame(graph, frame)
        method, file, line_no = @methods_table[frame.iseq]
        if file == nil
          method, file, line_no = frame.iseq.to_s, frame.iseq.to_s, frame.iseq.to_s
        end

        if file.include?("/")
          label = "#{method}(#{file.split("/")[-3..-1].join("/")}:#{line_no})"
        else
          label = "#{method}(#{file}:#{line_no})"
        end

        node = graph.add_nodes(frame.iseq.to_s + "-#{@fake_generation}", label: label, color: '#2e95d3', fontcolor: '#2e95d3')

        @fake_generation += 1
        frame.children.each do |child|
          duration = child.duration
          percentage = (duration / @total * 100).round(2)
          label = "#{duration/1000.0}ms (#{percentage}%)"
          child = draw_frame(graph, child)
          graph.add_edges(node, child, label: label, color: '#00a67d', fontcolor: '#00a67d') if child
        end

        node
      end

      def walk(target_trace_id)
        File.new(@log_file).each_line do |line|
          next if line.include?("[methods]")

          _, raw_data = line.split("[stack_frames]")
          next if raw_data.nil?
          data = JSON.parse(raw_data)
          trace_id = data[0]

          next if trace_id != target_trace_id

          ts = data[1]
          iseqs = data[2..-1].reverse # root to deeptest

          frame_diff_count = @stack.count - iseqs.count

          while frame_diff_count > 0
            @stack.pop
            frame_diff_count -= 1
          end

          i = 0

          iseqs.each do |iseq|
            if on_stack?(iseq, i)
              update_ts(i, ts)
            else
              on_stack(iseq, ts, i)
            end

            i += 1
          end
        end
      end

      private
      def update_ts(i, ts)
        frame = @stack[i]
        frame.update_ts(ts)
      end

      def on_stack?(iseq, i)
        @stack[i] && @stack[i].iseq == iseq
      end

      def on_stack(iseq, ts, i)
        frame = Frame.new(iseq, ts)
        if i == 0
          @roots << frame
        end

        @stack[i] = frame

        if i != 0
          pre_frame = @stack[i-1]
          frame.parent = pre_frame
          pre_frame.add_child(frame)
        end
      end

      def read_methods
        stacks = []

        iseq_to_method = {}

        File.new(@iseq_file).each_line do |line|
          data = JSON.parse(line)
          if data["event"] == 0
            stacks << data
          elsif data["event"] == 1
            start = stacks.pop
            addr = data['iseq_addr']
            iseq_to_method[addr] = start['name'], start['path'], start['first_lineno']
          else
            raise 'wrong type'
          end
        end

        puts "Lost end of iseq creation" if stacks != []
        iseq_to_method
      end
    end
  end
end
