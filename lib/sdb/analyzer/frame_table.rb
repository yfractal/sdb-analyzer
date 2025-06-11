# frozen_string_literal: true

module Sdb
  module Analyzer
    class FrameTable
      def initialize(frames)
        @frames = frames.group_by(&:thread_id)
        @frames.each do |thread_id, frames|
          @frames[thread_id] = frames.sort_by(&:ts)
        end
      end

      # request: RequestTable::Request
      def find_frames(request)
        thread_id = request.thread_id
        frames = @frames[thread_id]
        start_ts = request.start_ts
        end_ts = request.end_ts

        frames.select { |frame| frame.ts >= start_ts && frame.ts <= end_ts }
      end
    end
  end
end