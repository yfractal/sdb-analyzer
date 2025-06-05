# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::LogReader do
  it 'reads log into frames and symbols' do
    frames, symbols = Sdb::Analyzer::LogReader.read('./spec/data/sdb.log', 11111122)

    frame = frames.last
    expect(frame.class).to eq Sdb::Analyzer::FrameReader::Frame
    expect(frame.trace_id).to eq 11111122

    symbol = symbols.last
    expect(symbol.class).to eq Sdb::Analyzer::SymbolReader::Iseq
    expect(symbol.addr).to eq '4413785520'
    expect(symbol.label).to eq 'target!'
    expect(symbol.path).to eq '/Users/y/.rvm/gems/ruby-3.1.5/gems/jbuilder-2.12.0/lib/jbuilder/jbuilder_template.rb'
  end
end