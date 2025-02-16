module Sdb
  module Analyzer
    class Symbolizer
      def initialize(symbol_table, time_converter)
        @symbol_table = symbol_table
        @time_converter = time_converter
      end

      def translate_iseq(iseq_node)
        ts = @time_converter.clock_time_to_uptime(iseq_node.ts)

        @symbol_table.iseq(iseq_node.iseq, ts)
      end

      def translate(frame)
        iseqs = frame.iseqs
        ts = @time_converter.clock_time_to_uptime(frame.ts)

        iseqs.map {|iseq| @symbol_table.iseq(iseq, ts) }
      end
    end
  end
end
