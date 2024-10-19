# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::Puma do
  let (:analyzer) { Sdb::Analyzer::Puma.new('./data/puma.log') }
  it 'reads log into data' do
    data = analyzer.read

    expect(data[0][:trace_id]).to eq '1111111'
    expect(data[0][:delay]).to eq 120.947
  end

  it 'calcuates avg delay' do
    fake_data = [
      {delay: 1}, {delay: 2}, {delay: 3}
    ]

    expect(analyzer.average_delay(fake_data)).to eq 2.0
  end

  it 'calcuates avg cpu time' do
    fake_data = [
      {cpu_time: 1}, {cpu_time: 2}, {cpu_time: 3}
    ]

    expect(analyzer.average_delay(fake_data, :cpu_time)).to eq 2.0
  end
end
