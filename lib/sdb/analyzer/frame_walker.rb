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
      def initialize(traces_file, methods_file)
        @traces_file = File.new(traces_file)
        @methods_file = File.new(methods_file)
        @methods_table = read_methods
        @roots = []
        @stack = []
      end
  
      def draw(name)
        graph = GraphViz.new( :G, :type => :digraph )
        @fake_generation = 0
        @total = @roots.map {|root| root.duration }.sum.to_f
  
        @roots.each do |frame|
          draw_frame(graph, frame)
        end
  
        graph.output( :png => name )
      end
  
      def draw_frame(graph, frame)
        method, file, line_no = @methods_table[frame.iseq]
  
        return if file == nil
  
        percentage = (frame.duration / @total * 100).round(2)
        if file.include?("/")
          label = "#{file.split("/")[-4..-1].join("/")}:#{line_no}##{method} (#{frame.duration/1000.0} ms)(#{percentage}%)"
        else
          label = "#{file}:#{line_no}##{method} (#{frame.duration/1000.0} ms)(#{percentage}%)"
        end
  
        node = graph.add_nodes(frame.iseq.to_s + "-#{@fake_generation}", label: label)
  
        @fake_generation += 1
        frame.children.each do |child|
          child = draw_frame(graph, child)
          graph.add_edges(node, child) if child
        end
  
        node
      end
  
      def walk
        @traces_file.each_line do |line|
          _, raw_data = line.split("[stack_frames]")
          data = JSON.parse(raw_data)
          trace_id = data[0]
          ts = data[1]
          iseqs = data[2..-1].reverse # root to deeptest
  
          frame_diff_count = @stack.count - iseqs.count
  
          while frame_diff_count > 0
            @stack.pop
            frame_diff_count -= 1
          end
  
          i = 0
  
          iseqs.each do |iseq|
            method, file, _ = @methods_table[iseq]
  
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
        iseq_to_method = {}
  
        @methods_file.each_line do |line|
          _, data = line.split("[methods],")
          methods = data[1..-3].split("],[")
          methods.each do |method_line|
            iseq_addr, method, file, line_no = method_line.split(",")
            iseq_to_method[iseq_addr.to_i] = [method, file, line_no]
          end
        end
  
        iseq_to_method
      end
    end
  end
end