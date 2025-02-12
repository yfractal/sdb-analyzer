require 'json'

module Sdb
  module Analyzer
    class TimeConverter
      def self.from_log(line)
        # line example '2025-02-12 13:40:53.956155043 [INFO] [time] uptime=68385000000000, clock_time=1739367653956148'
        match_data = line.match(/uptime=(\d+), clock_time=(\d+)/)
        uptime = match_data[1].to_i
        clock_time = match_data[2].to_i

        Sdb::Analyzer::TimeConverter.new(uptime, clock_time)
      end

      def initialize(uptime, clock_time)
        @base_uptime = uptime
        @base_clock_time = clock_time
        # @diff = clock_time - uptime / 1000
      end

      def uptime_to_clock_time(uptime)
        uptime - @base_uptime + @base_clock_time
      end
    end
  end
end