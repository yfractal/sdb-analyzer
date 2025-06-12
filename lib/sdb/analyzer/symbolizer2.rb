module Sdb
  module Analyzer
    class Symbolizer2
      def initialize(symbols)
        @symbols = symbols

        @symbol_table = {}
        @symbols.group_by(&:process_id).each do |process_id, symbols|
          @symbol_table[process_id] = {}
          symbols.each do |symbol|
            @symbol_table[process_id][symbol.addr.to_i] = symbol
          end
        end
      end

      def iseq(process_id, iseq_addr, ts)
        @symbol_table[process_id][iseq_addr] || SymbolReader::Iseq.new_method(ts, process_id, 0, nil, nil)
      end

      def same_func?(iseq0, iseq1)
        return false if iseq0 == nil || iseq1 == nil

        iseq0.func_id == iseq1.func_id
      end
    end
  end
end
