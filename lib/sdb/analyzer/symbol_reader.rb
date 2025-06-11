# frozen_string_literal: true

module Sdb
  module Analyzer
    class SymbolReader
      Iseq = Struct.new(:func_id, :process_id, :addr, :ts, :label, :path) do
        def self.new_method(ts, process_id, addr, label, path)
          func_id = "#{addr}-#{ts}"

          self.new(func_id, process_id, addr, ts, label, path)
        end
      end

      def self.read(raw_symbols)
        raw_symbols.map do |ts, process_id, raw_symbol|
          addr, label, path = raw_symbol.split(',')
          Iseq.new_method(ts, process_id, addr.strip, label.strip, path.strip)
        end
      end
    end
  end
end