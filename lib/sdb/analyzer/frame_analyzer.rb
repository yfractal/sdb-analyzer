# frozen_string_literal: true

require 'json'

module Sdb
  module Analyzer
    # FrameAnalyzer is for converting frames to call-graph
    class FrameAnalyzer
      class IseqNode
        attr_writer :parent
        attr_reader :children, :duration, :iseq, :parent

        # frame is FrameWalker::Frame
        def initialize(iseq, frame)
          @iseq     = iseq
          @frame    = frame
          @duration = 0
          @children = []
          @parent   = nil
        end

        def add_child(frame)
          @children << frame
        end

        def update_duration(new_ts)
          @duration = new_ts - ts
        end

        def ts
          @frame.ts
        end
      end

      attr_reader :roots
      def initialize(frames)
        @frames = frames
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

          iseqs.each do |iseq|
            if on_stack?(iseq, i)
              update_duration(i, ts)
            else
              push_on_stack(frame, iseq, i)
            end

            i += 1
          end
        end
      end

      private

      def on_stack?(iseq, i)
        @stack[i] && @stack[i].iseq == iseq
      end

      def update_duration(i, ts)
        @stack[i].update_duration(ts)
      end

      def push_on_stack(frame, iseq, i)
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
    end
  end
end
