# frozen_string_literal: true
require 'ruby-graphviz'
require 'json'

module Sdb
  module FrameWalker
    class Frame
      attr_writer :parent
      attr_reader :trace_id, :iseq, :ts, :children, :duration

      def initialize(trace_id, iseq, ts)
        @trace_id = trace_id
        @iseq     = iseq
        @ts       = ts
        @duration = 0
        @children = []
        @parent   = nil
      end

      def add_child(frame)
        @children << frame
      end

      def update_duration(new_ts)
        @duration = new_ts - @ts
      end
    end

    class Walker
      attr_accessor :methods_table

      def initialize(log_file, iseq_file)
        @log_file = log_file
        @iseq_file = iseq_file
        @symbols_table = Sdb::Analyzer::SymbolsTable.new(iseq_file)
        @methods_table =  @symbols_table.read
        @roots = []
        @stack = []
        @metas = []
      end

      def stack_depth
        @depth = []
        @roots.each do |frame|
          frame_stack_depth(frame, 0)
        end

        puts @depth.sum / @depth.count.to_f
      end

      def frame_stack_depth(frame, depth)
        if frame.children.count == 0
          @depth << depth
          puts "depth=#{depth}"
        else
          frame.children.each do |child|
            frame_stack_depth(child, depth + 1)
          end
        end
      end

      def draw(name)
        graph = GraphViz.new( :G, :type => :digraph )
        graph[:bgcolor] = '#253238'
        @fake_generation = 0
        @total = @roots.map {|root| root.duration }.sum.to_f

        @roots.each do |frame|
          meta = find_meta(frame)
          meta[:frame_count] = 0
          meta[:iseqs_count] = 0
          meta[:c_iseqs_count] = 0
          meta[:no_symobls_count] = 0
          meta[:duration] = frame.duration
          meta[:captured_duration_count] = 0

          draw_frame(graph, frame, meta)

          if meta[:controller_entry]
            controller = "#{meta[:controller_entry][:file].split('/')[-1].gsub('.rb', '').split('_').map(&:capitalize).join}##{meta[:controller_entry][:method]}"
            label = "controller: #{controller}, status: #{meta[:status]}"
          else
            label = 'dummy' # TODO: fix me
          end

          graph.add_nodes("labels", label: label, color: '#2e95d3', fontcolor: '#2e95d3')

          puts "meta=#{meta}"
        end

        graph.output( :png => name )
      end

      def draw_frame(graph, frame, meta)
        meta[:iseqs_count] += 1

        if frame.children.count == 0
          meta[:frame_count] += 1
        end

        if frame.iseq == 0
          meta[:c_iseqs_count] += 1
        end

        if frame.duration != 0
          meta[:captured_duration_count] += 1
        end

        method, file, line_no = @methods_table[frame.iseq]
        if method == nil
          meta[:no_symobls_count] += 1
        end

        if file == nil
          method, file, line_no = frame.iseq.to_s, "", "0"
        end

        if file.include?('app/controllers') && meta[:controller_entry].nil?
          meta[:controller_entry] = {file: file, method: method}
        end

        if file.include?("/") && !file.split("/")[-3..-1].nil?
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
          child = draw_frame(graph, child, meta)
          graph.add_edges(node, child, label: label, color: '#00a67d', fontcolor: '#00a67d') if child
        end

        node
      end

      def walk(target_trace_id)
        # filter out the stack frames
        rows = []

        File.new(@log_file).each_line do |line|
          if line.include?("[SDB][puma-delay]")
            @metas << Analyzer::Puma.read_line(line)
          elsif line.include?("[stack_frames]")
            _, raw_data = line.split("[stack_frames]")

            data = JSON.parse(raw_data)

            rows << data
          end
        end

        frames = Sdb::Analyzer::FrameReader.read(rows)
        iseqs = [] # not need this ..
        frames.each do |frame|
          next if frame[0] != target_trace_id
          frame.each {|method| iseqs << method}

          ts = frame[1]
          iseqs = frame[2..-1].reverse # root to deepest

          frame_diff_count = @stack.count - iseqs.count

          while frame_diff_count > 0
            @stack.pop
            frame_diff_count -= 1
          end

          i = 0

          iseqs.each do |iseq|
            if on_stack?(iseq, i)
              update_duration(i, ts)
            else
              on_stack(frame[0], iseq, ts, i)
            end

            i += 1
          end
        end

        iseqs.uniq # todo: remove this line
      end

      private
      def find_meta(frame)
        @metas.each do |meta|
          # TODO: frame's ts and meta's ts is fetched in different threads
          # they may not match exactly. So may need some buffer
          if frame.trace_id == meta[:trace_id] && (frame.ts < meta[:start_ts] || frame.ts + frame.duration > meta[:end_ts])
            diff0 = (meta[:start_ts] - frame.ts) / 1_000_000
            puts "frame sratrted #{diff0} seconds before puma record"

            diff1 = (frame.ts + frame.duration - meta[:end_ts]) / 1_000_000
            puts "frame ended #{diff1} seconds after puma record"
          end

          if frame.trace_id == meta[:trace_id] && frame.ts >= meta[:start_ts] && frame.ts + frame.duration <= meta[:end_ts]
            return meta
          end
        end
      end

      def update_duration(i, ts)
        frame = @stack[i]
        frame.update_duration(ts)
      end

      def on_stack?(iseq, i)
        @stack[i] && @stack[i].iseq == iseq
      end

      def on_stack(trace_id, iseq, ts, i)
        frame = Frame.new(trace_id, iseq, ts)
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

      end
    end
  end
end
