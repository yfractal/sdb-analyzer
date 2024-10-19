# frozen_string_literal: true

module Sdb
  module Analyzer
    class Puma
      def initialize(log)
        @log = log
      end

      def read
        data = []
        File.new(@log).each_line do |line|
          if line.include? '[SDB][puma-delay]'
            content = line.split('[SDB][puma-delay]:')[-1].strip
            data << content.split(', ').map do |pair|
              key, value = pair.split('=')

              if value.include? 'ms'
                value = value.gsub(/ ms/, '').to_f
              end

              [key.to_sym, value]
            end.to_h
          end
        end

        data
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

      def p_x(percentage, array)
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
