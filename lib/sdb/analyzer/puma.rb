# frozen_string_literal: true

module Sdb
  module Analyzer
    class Puma
      class << self
        def read_line(line)
          content = line.split('[SDB][puma-delay]:')[-1].strip
          content.split(', ').map do |pair|
            key, value = pair.split('=')

            if value.include? 'ms'
              value = value.gsub(/ ms/, '').to_f
            end

            if key == 'trace_id'
              value = value.to_i # trace_id is integer
            end

            [key.to_sym, value]
          end.to_h
        end
      end

      def initialize(log)
        @log = log
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

      def statistic(data)
        {
          total: data.count,
          avg: average_delay(data),
          cpu_time_avg: average_delay(data, :cpu_time),
          p50: p_x(50, data, :delay),
          cpu_time_p50: p_x(50, data, :cpu_time),
          p90: p_x(90, data, :delay),
          cpu_time_p90: p_x(90, data, :cpu_time),
          p99: p_x(99, data, :delay),
          cpu_time_p99: p_x(99, data, :cpu_time),
        }
      end

      private

      def average_delay(data, type = :delay)
        if type == :delay
          times = data.map {|d| d[:delay]}
          times.sum.to_f / times.count
        elsif type == :cpu_time
          times = data.map {|d| d[:cpu_time]}
          times.sum.to_f / times.count
        end
      end

      def p_x(percentage, data, field)
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
