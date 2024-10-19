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
    end
  end
end
