# frozen_string_literal: true

require 'json'

module Sdb
  module Analyzer
    class LogReader
      def self.read_sdb_log(log, trace_id = nil)
        time_converter = nil
        raw_frames = []

        File.new(log).each_line do |line|
          if line.include?('[time]')
            time_converter = Sdb::Analyzer::TimeConverter.from_log_line(line)
          elsif line.include?('[stack_frames]')
            _, raw_data = line.split('[stack_frames]')

            raw_frames << JSON.parse(raw_data)
          else
            puts "unexpected line #{line}"
          end
        end

        frames = Sdb::Analyzer::FrameReader.read_raw_frames(raw_frames)

        if trace_id
          frames = frames.select { |frame| frame.trace_id == trace_id }
        end

        [time_converter, frames]
      end
    end
  end
end
