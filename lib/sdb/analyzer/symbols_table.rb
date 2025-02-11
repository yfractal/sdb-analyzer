require 'json'

module Sdb
  module Analyzer
    class SymbolsTable
      def initialize(file)
        @file = file
      end

      def read
        iseq_to_method = {}
        cfunc_first_event = nil

        module_addr_to_name = {}
        define_module_enter = nil

        File.new(@file).each_line do |line|
          data = JSON.parse(line)
          if data['type'] == 5
            define_module_enter = data
          elsif data['type'] == 6
            if define_module_enter
              module_addr_to_name[data['iseq_addr']] = {
                :name => define_module_enter['name'],
                :addr => data['iseq_addr']
              }

              define_module_enter = nil
            end
          elsif data['type'] == 3
            cfunc_first_event = data
          elsif data['type'] == 4
            if cfunc_first_event
              module_addr = cfunc_first_event['iseq_addr']
              module_name = module_addr_to_name[module_addr]
              addr = data['iseq_addr']
              iseq_to_method[addr] = cfunc_first_event['name'], module_name, cfunc_first_event['first_lineno'], cfunc_first_event['type']
              cfunc_first_event = nil
            end
          else
            addr = data['iseq_addr']
            iseq_to_method[addr] = data['name'], data['path'], data['first_lineno'], data['type']
          end
        end

        iseq_to_method
      end
    end
  end
end