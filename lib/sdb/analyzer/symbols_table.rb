require 'json'

module Sdb
  module Analyzer
    class SymbolsTable
      Iseq = Struct.new(:func_id, :addr, :ts, :type, :name, :path_or_module, :first_lineno, :source) do
        def self.new_method(addr, ts, type, name, path_or_module, first_lineno, source)
          func_id = "#{addr}-#{ts}"

          self.new(func_id, addr, ts, type, name, path_or_module, first_lineno, source)
        end

        def self.moved_method(iseq, new_addr, new_ts, source)
          new_iseq = iseq.clone

          # a moved method has new addr and new ts but all others are same
          new_iseq.addr = new_addr
          new_iseq.ts = new_ts
          new_iseq.source = source

          new_iseq
        end
      end

      def self.from_log(file)
        table = self.new
        File.new(file).each_line do |line|
          data = JSON.parse(line)
          table.read_line(data)
        end

        table
      end

      # struct
      #   iseq_addr => [iseq0, iseq1 ...]
      attr_reader :iseq_addr_to_iseq

      def initialize
        @methods_move_events = [] # for debugging
        @iseq_addr_to_iseq = {}

        # for reading c functions
        @cfunc_first_event = nil
        @module_addr_to_name = {}
        @define_module_enter_event = nil
      end

      def iseq(addr, ts)
        iseqs = @iseq_addr_to_iseq[addr]
        return if iseqs.nil? || iseqs.empty?

        if iseqs.size == 1 && iseqs[0].ts >= ts
          return iseqs[0]
        else
          i = 0
          while i < iseqs.size
            if i == iseqs.size - 1 && ts >= iseqs[i].ts
              return iseqs[i]
            elsif iseqs[i].ts <= ts && ts < iseqs[i + 1].ts
              return iseqs[i]
            end

            i += 1
          end
        end

        nil
      end

      def read_line(data)
        if data['type'] == 5
          @define_module_enter_event = data
        elsif data['type'] == 6
          if @define_module_enter_event
            @module_addr_to_name[data['iseq_addr']] = {
              :name => @define_module_enter_event['name'],
              :addr => data['iseq_addr']
            }

            @define_module_enter_event = nil
          end
        elsif data['type'] == 3
          @cfunc_first_event = data
        elsif data['type'] == 4
          if @cfunc_first_event
            module_addr = @cfunc_first_event['iseq_addr']
            module_name = @module_addr_to_name[module_addr]
            addr = data['iseq_addr']
            ts = data['ts']

            @iseq_addr_to_iseq[addr] ||= []
            iseq = Iseq.new_method(addr, ts, :c_func, @cfunc_first_event['name'], module_name, @cfunc_first_event['first_lineno'], [@cfunc_first_event, data])
            @iseq_addr_to_iseq[addr] << iseq
            @iseq_addr_to_iseq[addr].sort_by! { |iseq| iseq.ts }

            @cfunc_first_event = nil
          end
        elsif data['type'] != 7 # move event
          addr = data['iseq_addr']
          # TODO fix me
          if addr == 0
            # puts "addr is 0, data=#{data}"
            return
          end
          ts = data['ts']

          iseq = Iseq.new_method(addr, data['ts'], :ruby_func, data['name'], data['path'], data['first_lineno'], data)
          @iseq_addr_to_iseq[addr] ||= []
          @iseq_addr_to_iseq[addr] << iseq
          @iseq_addr_to_iseq[addr].sort_by! { |iseq| iseq.ts }
        else
          from_addr, to_addr, ts = data['iseq_addr'], data['to_addr'], data['ts']
          if @iseq_addr_to_iseq[from_addr]
            # it moves the most recent record
            old_iseq = @iseq_addr_to_iseq[from_addr][-1]
            iseq = Iseq.moved_method(old_iseq, to_addr, data['ts'], data)
            @iseq_addr_to_iseq[to_addr] ||= []
            @iseq_addr_to_iseq[to_addr] << iseq
            @iseq_addr_to_iseq[to_addr].sort_by! { |iseq| iseq.ts }

            @methods_move_events << data
          end
        end
      end
    end
  end
end
