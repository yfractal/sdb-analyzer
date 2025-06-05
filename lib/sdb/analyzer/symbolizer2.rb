module Sdb
  module Analyzer
    class Symbolizer2
      def initialize(symbols)
        @symbols = symbols

        @symbol_table = {}
        @symbols.each do |symbol|
          @symbol_table[symbol.addr.to_i] = symbol
        end
      end

      def iseq(iseq_addr, ts)
        @symbol_table[iseq_addr] || SymbolReader::Iseq.new_method(ts, 0, nil, nil)
      end

      def same_func?(iseq0, iseq1)
        return false if iseq0 == nil || iseq1 == nil

        iseq0.func_id == iseq1.func_id
      end
    end
  end
end
