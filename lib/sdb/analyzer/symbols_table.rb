require 'json'

module Sdb
  module Analyzer
    class SymbolsTable
      def initialize(file)
        @file = file
        @methods_move_events = [] # for debugging
      end

      def iseq(addr, ts)
        iseqs = @iseq_to_method[addr]
        return if iseqs.nil? || iseqs.empty?

        i = 0
        while i < iseqs.size
          if i == iseqs.size - 1
            return iseqs[i]
          elsif iseqs[i][-1] <= ts && iseqs[i + 1][-1] > ts
            return iseqs[i]
          end

          i += 1
        end
      end

      def read
        @iseq_to_method = {}
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

              ts = data['ts']
              @iseq_to_method[addr] ||= []
              @iseq_to_method[addr] << [addr, cfunc_first_event['name'], module_name, cfunc_first_event['first_lineno'], cfunc_first_event['type'], data['type'], data['ts']]
              @iseq_to_method[addr].sort_by! { |iseq| iseq[-1] }
              cfunc_first_event = nil
            end
          elsif data['type'] != 7 # move event
            addr = data['iseq_addr']
            # TODO fix me
            if addr == 0
              # puts "addr is 0, data=#{data}"
              next
            end

            ts = data['ts']

            @iseq_to_method[addr] ||= []
            @iseq_to_method[addr] << [addr, data['name'], data['path'], data['first_lineno'], data['type'], data['type'], ts]
            @iseq_to_method[addr].sort_by! { |iseq| iseq[-1] }
          else
            from_addr, to_addr, ts = data['iseq_addr'], data['to_addr'], data['ts']
            if @iseq_to_method[from_addr]
              # it moves the most recent record
              new_iseq = @iseq_to_method[from_addr][-1].clone
              new_iseq[-1] = ts
              @iseq_to_method[to_addr] ||= []
              @iseq_to_method[to_addr] << new_iseq
              @iseq_to_method[to_addr].sort_by! { |iseq| iseq[-1] }
              @methods_move_events << data
            end
          end
        end

        @iseq_to_method
      end
    end
  end
end