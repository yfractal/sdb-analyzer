RSpec.describe Sdb::Analyzer::SymbolsTable do
  describe '#iseq' do
    let (:data) {
      [
        {'ts' => 10, 'first_lineno' => 35, 'name' => 'foo', 'path' => 'some-path', 'iseq_addr' => 10000, 'to_addr' => 0, 'type' => 0},
        {'ts' => 20, 'first_lineno' => 0, 'name' => '', 'path' => '', 'iseq_addr' => 10000, 'to_addr' => 20000, 'type' => 7}, # gc_move
        {'ts' => 30, 'first_lineno' => 35, 'name' => 'bar', 'path' => 'some-path', 'iseq_addr' => 10000, 'to_addr' => 0, 'type' => 0}
      ]
    }

    let(:symbols_table) {
      table = described_class.new
      data.each { |d| table.read_line(d) }
      table
    }

    it 'returns nil if the ts is before the iseq event' do
      iseq = symbols_table.iseq(10000, 9)
      expect(iseq).to eq nil
    end

    it 'returns the iseq with the right ts' do
      iseq = symbols_table.iseq(10000, 11)
      expect(iseq).not_to eq nil
      expect(iseq.func_id).to eq '10000-10'
    end

    it 'quires the iseq with the new addr' do
      iseq = symbols_table.iseq(20000, 20)
      expect(iseq).not_to eq nil
      expect(iseq.func_id).to eq '10000-10'
    end

    it 'quires the new addr' do
      iseq = symbols_table.iseq(10000, 31)
      expect(iseq).not_to eq nil
      expect(iseq.func_id).to eq '10000-30'
    end
  end

  describe 'symbols from log' do
    let(:symbols_table) { described_class.from_log('./spec/data/symbols_table.log') }
    let(:iseq_addr_to_iseq) { symbols_table.iseq_addr_to_iseq }

    describe '#read' do
      it 'reads symbols' do
        iseq = iseq_addr_to_iseq[281473520570960][0]
        expect(iseq.addr).to eq 281473520570960
        expect(iseq.name).to eq 'fffffff'
        expect(iseq.path_or_module).to eq 'some-path'
        expect(iseq.type).to eq :ruby_func
      end

      it 'reads move events' do
        move_events = symbols_table.instance_variable_get("@methods_move_events")
        move_event = move_events[0]
        from_addr, to_addr = move_event['iseq_addr'], move_event['to_addr']
        old_iseq = iseq_addr_to_iseq[from_addr][0]
        new_iseq = iseq_addr_to_iseq[to_addr][0]

        expect(old_iseq.func_id).to eq new_iseq.func_id
        expect(new_iseq.source['iseq_addr']).to eq old_iseq.addr
        expect(new_iseq.source['to_addr']).to eq new_iseq.addr
      end
    end
  end
end
