# frozen_string_literal: true

module Sdb
  module Analyzer
    class PumaLogAnalyzer
      class << self
        def from_log(log)
          data = []
          File.new(log).each_line do |line|
            if line.include? '[SDB][puma-delay]'
              data << self.read_line(line)
            end
          end

          self.new(data)
        end

        private

        def read_line(line)
          content = line.split('[SDB][puma-delay]:')[-1].strip
          content.split(', ').map do |pair|
            key, value = pair.split('=')

            if value.include? 'ms'
              value = value.gsub(/ ms/, '').to_f
            end

            if key == 'trace_id'
              value = value.to_i
            end

            if key == 'start_ts' || key == 'end_ts'
              value = value.to_f
            end

            [key.to_sym, value]
          end.to_h
        end
      end

      attr_accessor :data

      def initialize(data)
        @data = data
      end

      def read
        data = []
        File.new(@log).each_line do |line|
          if line.include? '[SDB][puma-delay]'
            data << self.class.read_line(line)
          end
        end

        data
      end

      def statistic
        {
          total: data.count,
          avg: average_delay,
          cpu_time_avg: average_delay(:cpu_time),
          p50: p_x(50, :delay),
          cpu_time_p50: p_x(50, :cpu_time),
          p90: p_x(90, :delay),
          cpu_time_p90: p_x(90, :cpu_time),
          p99: p_x(99, :delay),
          cpu_time_p99: p_x(99, :cpu_time),
        }
      end

      private

      def average_delay(field = :delay)
        times = data.map {|d| d[field]}
        times.sum.to_f / times.count
      end

      def p_x(percentage, field)
        numbers = data.map{|d| d[field]}
        p_x_helper(percentage, numbers)
      end

      def p_x_helper(percentage, array)
        return nil if array.empty?

        sorted = array.sort

        rank = percentage.to_f / 100 * (sorted.size - 1)
        lower_index = rank.floor
        upper_index = rank.ceil

        if lower_index == upper_index
          sorted[lower_index]
        else
          lower_value = sorted[lower_index]
          upper_value = sorted[upper_index]
          lower_value + (upper_value - lower_value) * (rank - lower_index)
        end
      end
    end
  end
end
