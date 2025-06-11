# frozen_string_literal: true

module Sdb
  module Analyzer
    # SDB writes frames in batch, one log line contains multiple frames
    # FrameReader is used for separating one log line into multiple frames
    class FrameReader
      SEPARATOR = 18446744073709551615

      class Frame
        attr_reader :thread_id, :ts, :iseqs

        def self.from_raw(raw_frame)
          thread_id, ts, _ = raw_frame
          iseqs = raw_frame[2..].reverse # root to deepest
          self.new(thread_id, ts, iseqs)
        end

        def initialize(thread_id, ts, iseqs)
          @thread_id = thread_id
          @ts = ts
          @iseqs = iseqs
        end
      end

      class << self
        def read(data)
          frames = []
          frame = []

          i = 0
          while i < data.count
            current_row = data[i]
            next_row = data[i + 1]
            j = 0

            while j < current_row.count
              if current_row[j] == SEPARATOR
                j += 1
              elsif frame_ended?(j, current_row, next_row)
                frame << current_row[j]
                frames << frame
                frame = []

                # current, separator, separator, next
                j += 3
              else
                frame << current_row[j]
                j += 1
              end
            end

            i += 1
          end

          frames
        end

        def read_raw_frames(data)
          raw_frames = self.read(data)
          raw_frames.map { |raw_frame| Frame.from_raw(raw_frame) }
        end

        private

        def frame_ended?(i, current_row, next_row)
          next_row ||= []

          (current_row[i+1] == SEPARATOR && current_row[i+2] == SEPARATOR) ||
            (current_row[i+2] == nil && current_row[i+1] == SEPARATOR && next_row[0] == SEPARATOR) ||
            (current_row[i+1] == nil && next_row[0] == SEPARATOR && next_row[1] == SEPARATOR)
        end
      end
    end
  end
end
