RSpec.describe Sdb::Analyzer::SymbolsTable do
  before do
    @symbols_table = described_class.new('./spec/data/symbols_table.log')
    @symbols = @symbols_table.read
  end

  describe '#read' do
    it 'reads symbols' do
      expect(@symbols[281473520570960][0]).to eq(["fffffff", "some-path", 35, 0, 0, 8126901797125])
    end

    it 'reads move events' do
      move_events = @symbols_table.instance_variable_get("@methods_move_events")
      move_event = move_events[0]
      from_addr, to_addr = move_event['iseq_addr'], move_event['to_addr']
      old_iseq = @symbols[from_addr][0]
      new_iseq = @symbols[to_addr][0]

      expect(old_iseq[0...-1]).to eq(new_iseq[0...-1])
    end
  end

  describe '#iseq' do
    it 'reads iseq' do
      # addr = 281472935568280
      # [["<top (required)>", "/root/.rbenv/versions/3.1.5/lib/ruby/3.1.0/rubygems/errors.rb", 0, 0, 0, 8126494524917], ["sanitize_string", "/root/.rbenv/versions/3.1.5/lib/ruby/3.1.0/rubygems/specification.rb", 1496, 0, 0, 8126504728750]]
      iseq = @symbols_table.iseq(281472935568280, 8126494524918)
      expect(iseq).to eq ["<top (required)>", "/root/.rbenv/versions/3.1.5/lib/ruby/3.1.0/rubygems/errors.rb", 0, 0, 0, 8126494524917]
    end

    it 'returns 0 if no such addr' do
      iseq = @symbols_table.iseq(0, 0)
      expect(iseq).to eq nil
    end
  end
end
