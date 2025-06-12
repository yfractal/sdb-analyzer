# frozen_string_literal: true

module Sdb
  module Analyzer
    class FrameTable
      def initialize(frames)
        @frames = {}

        frames.group_by(&:process_id).each do |process_id, frames|
          frames.group_by(&:thread_id).each do |thread_id, frames|
            @frames[process_id] ||= {}
            @frames[process_id][thread_id] = frames.sort_by(&:ts)
          end
        end
      end

      # request: RequestTable::Request
      def find_frames(request)
        frames = @frames[request.process_id][request.thread_id]
        start_ts = request.start_ts
        end_ts = request.end_ts

        frames.select { |frame| frame.ts >= start_ts && frame.ts <= end_ts }
      end
    end
  end
end