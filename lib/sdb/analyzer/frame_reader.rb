# frozen_string_literal: true

module Sdb
  module Analyzer
    class FrameReader
      SEPARATOR = 18446744073709551615

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

                # current, seperator, seperator, next
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
