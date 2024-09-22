require 'json'

module Sdb
  module FrameWalker
    module Helper
      class Stack
        attr_accessor :trace_id, :ts, :frames, :log_ts

        def initialize(log_ts, raw_data)
          data = JSON.parse(raw_data)
          @log_ts = log_ts
          @trace_id = data[0]
          @ts = data[1]
          @frames = data[2..-1]
        end

        def same?(stack)
          @trace_id == stack.trace_id && @frames == stack.frames
        end

        def update(stack)
          @left_ts = stack.ts
          @left_log_ts = stack.log_ts
        end

        def to_s
          data = [@trace_id, @ts]
          data += @frames
          log = "#{@log_ts} [stack_frames]#{data.to_json}"

          if @left_ts
            data = [@trace_id, @left_ts]
            data += @frames
            left_log = "#{@left_log_ts} [stack_frames]#{data.to_json}"
            "#{log}\n#{left_log}"
          else
            log
          end
        end
      end

      def self.compact(file, output_file)
        current_stack = nil
        stacks = []

        File.new(file).each_line do |line|
          next if line.include?("[methods]")

          log_ts, raw_data = line.split("[stack_frames]")
          if current_stack == nil
            current_stack = Stack.new(log_ts, raw_data)
            stacks << current_stack
          else
            new_stack = Stack.new(log_ts, raw_data)

            if current_stack.same?(new_stack)
              current_stack.update(new_stack)
            else
              stacks << new_stack
              current_stack = new_stack
            end
          end
        end

        File.open(output_file, "w") do |file|
          file.puts(stacks.join("\n"))
        end
      end
    end
  end
end
