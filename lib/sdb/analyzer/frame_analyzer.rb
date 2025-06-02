# frozen_string_literal: true

require 'json'

module Sdb
  module Analyzer
    # FrameAnalyzer is for converting frames to call-graph
    class FrameAnalyzer
      class IseqNode
        attr_writer :parent, :children
        attr_reader :children, :duration, :iseq, :parent, :frame

        # iseq: SymbolsTable::Iseq
        # frame: FrameReader::Frame
        def initialize(iseq, frame)
          @iseq     = iseq
          @frame    = frame
          @duration = 0
          @children = []
          @parent   = nil
        end

        def add_child(node)
          @children << node
        end

        def update_duration(new_ts)
          @duration = new_ts - ts
        end

        def ts
          @frame.ts
        end
      end

      attr_reader :roots

      def initialize(frames, symbolizer)
        @frames = frames
        @symbolizer = symbolizer
        @stack = []
        @roots = []
      end

      def walk
        @frames.each do |frame|
          ts = frame.ts
          iseqs = frame.iseqs

          frame_diff_count = @stack.count - iseqs.count

          while frame_diff_count.positive?
            @stack.pop
            frame_diff_count -= 1
          end

          i = 0
          @not_on_stack = false

          iseqs.each do |iseq|
            if on_stack?(iseq, i, ts)
              update_duration(i, ts)
            else
              push_on_stack(frame, i)
            end

            i += 1
          end
        end

        @roots
      end

      private

      def on_stack?(iseq_addr, i, ts)
        return false if @not_on_stack
        iseq = find_iseq(iseq_addr, ts)
        if !@stack[i]
          @not_on_stack = true
          return false
        end

        same_func = same_func?(@stack[i].iseq, iseq)

        if !same_func
          @not_on_stack = true
        end

        same_func
      end

      def update_duration(i, ts)
        @stack[i].update_duration(ts)
      end

      def push_on_stack(frame, i)
        iseq_addr = frame.iseqs[i]
        # addr, ts, type, name, path_or_module, first_lineno, source
        iseq = find_iseq(iseq_addr, frame.ts)

        node = IseqNode.new(iseq, frame)

        if i == 0
          @roots << node
        end

        @stack[i] = node

        if i != 0
          pre_iseq_node = @stack[i-1]
          node.parent = pre_iseq_node
          pre_iseq_node.add_child(node)
        end
      end

      def find_iseq(iseq_addr, ts)
        @symbolizer.iseq(iseq_addr, ts)
      end

      def same_func?(iseq0, iseq1)
        @symbolizer.same_func?(iseq0, iseq1)
      end
    end
  end
end
