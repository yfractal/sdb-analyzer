# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::Puma do
  it 'reads log into data' do
    puma_analyzer = Sdb::Analyzer::Puma.new('./data/puma.log')
    data = puma_analyzer.read

    expect(data[0][:trace_id]).to eq '1111111'
    expect(data[0][:delay]).to eq 120.947
  end
end
