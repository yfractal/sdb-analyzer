RSpec.describe Sdb::Analyzer::SymbolsTable do
  describe '#read' do
    before do
      @symbols_table = described_class.new('./spec/data/symbols_table.log')
      @symbols = @symbols_table.read
    end

    it 'reads symbols' do
      expect(@symbols[281473520570960]).to eq({8126901797125 => ["fffffff", "some-path", 35, 0, 0, 8126901797125]})
    end

    it 'reads move events' do
      move_events = @symbols_table.instance_variable_get("@methods_move_events")
      move_event = move_events[0]
      from_addr, to_addr = move_event['iseq_addr'], move_event['to_addr']
      old_iseq = @symbols[from_addr].values.first
      new_iseq = @symbols[to_addr].values.first

      expect(old_iseq[0...-1]).to eq(new_iseq[0...-1])
    end
  end
end
