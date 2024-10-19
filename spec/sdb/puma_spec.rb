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

    expect(analyzer.send(:average_delay, fake_data)).to eq 2.0
  end

  it 'calcuates avg cpu time' do
    fake_data = [
      {cpu_time: 1}, {cpu_time: 2}, {cpu_time: 3}
    ]

    expect(analyzer.send(:average_delay, fake_data, :cpu_time)).to eq 2.0
  end

  it 'p90' do
    data = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    expect(analyzer.send(:p_x, 90, data)).to eq 91.0
  end

  it 'p99' do
    data = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    expect(analyzer.send(:p_x, 99, data)).to eq 99.1
  end
end
