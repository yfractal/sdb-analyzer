# frozen_string_literal: true

require 'json'
require 'time'

module Sdb
  module Analyzer
    class LogReader
      def self.read(log, trace_id = nil)
        raw_frames = []
        raw_symbols = []

        File.new(log).each_line do |line|
          if line.include?('[stack_frames]')
            prefix, raw_data = line.split('[stack_frames]')
            match = prefix.match(/\[INFO\]\s*\[(\d+)\]/)
            process_id = match[1].to_i
            data = JSON.parse(raw_data)
            data << process_id
            raw_frames << data
          elsif line.include?('[symbol]')
            prefix, raw_data = line.split('[symbol]')
            time = Time.parse(prefix.gsub("[INFO]", "").strip)
            ts = (time.to_f * 1000_000).to_i
            match = prefix.match(/\[INFO\]\s*\[(\d+)\]/)
            process_id = match[1].to_i
            raw_symbols << [ts, process_id, raw_data]
          else
            puts "unexpected line #{line}"
          end
        end

        frames = Sdb::Analyzer::FrameReader.read_raw_frames(raw_frames)
        symbols = Sdb::Analyzer::SymbolReader.read(raw_symbols)

        if trace_id
          frames = frames.select { |frame| frame.trace_id == trace_id }
        end

        [frames, symbols]
      end


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
