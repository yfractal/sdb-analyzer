# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::LogReader do
  it 'reads log into symbols' do
    _, symbols = Sdb::Analyzer::LogReader.read('./spec/data/symbols.log')

    symbol = symbols.first
    expect(symbol.class).to eq Sdb::Analyzer::SymbolReader::Iseq
    expect(symbol.process_id).to eq 35825
    expect(symbol.addr).to eq '4805306120'
    expect(symbol.label).to eq 'process_client'
    expect(symbol.path).to eq '/Users/y/.rvm/gems/ruby-3.3.0/gems/puma-6.4.2/lib/puma/server.rb'

    symbol1 = symbols[1]
    expect(symbol1.process_id).to eq 35820
    expect(symbol1.addr).to eq '4805308600'
    expect(symbol1.label).to eq 'block in run'
    expect(symbol1.path).to eq '/Users/y/.rvm/gems/ruby-3.3.0/gems/puma-6.4.2/lib/puma/server.rb'
  end
end
