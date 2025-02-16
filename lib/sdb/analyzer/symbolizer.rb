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

      def iseq(iseq_addr, ts)
        @symbol_table.iseq(iseq_addr, ts)
      end

      def same_func?(iseq0, iseq1)
        return false if iseq0 == nil || iseq1 == nil

        iseq0.func_id == iseq1.func_id
      end

      def translate(frame)
        iseqs = frame.iseqs
        ts = @time_converter.clock_time_to_uptime(frame.ts)

        iseqs.map {|iseq| @symbol_table.iseq(iseq, ts) }
      end
    end
  end
end
