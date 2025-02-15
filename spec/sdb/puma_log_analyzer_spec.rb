# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::PumaLogAnalyzer do
  describe 'from file' do
    it 'reads log and returns analyzer object' do
      analyzer = Sdb::Analyzer::PumaLogAnalyzer.from_log('./data/puma.log')

      expect(analyzer.data[0][:trace_id]).to eq 1111111
      expect(analyzer.data[0][:delay]).to eq 120.947
    end
  end

  describe 'calculation' do
    it 'calculates avg delay' do
      data = [
        {delay: 1}, {delay: 2}, {delay: 3}
      ]
      analyzer = described_class.new(data)

      expect(analyzer.send(:average_delay)).to eq 2.0
    end

    it 'calculates avg cpu time' do
      data = [
        {cpu_time: 1}, {cpu_time: 2}, {cpu_time: 3}
      ]
      analyzer = described_class.new(data)

      expect(analyzer.send(:average_delay, :cpu_time)).to eq 2.0
    end

    it 'calculates p90' do
      data = [
        {delay: 10}, {delay: 20}, {delay: 30}, {delay: 40}, {delay: 50}, {delay: 60}, {delay: 70}, {delay: 80}, {delay: 90}, {delay: 100}
      ]
      analyzer = described_class.new(data)

      expect(analyzer.send(:p_x, 90, :delay)).to eq 91.0
    end

    it 'calculates p99' do
      data = [
        {delay: 10}, {delay: 20}, {delay: 30}, {delay: 40}, {delay: 50}, {delay: 60}, {delay: 70}, {delay: 80}, {delay: 90}, {delay: 100}
      ]
      analyzer = described_class.new(data)

      expect(analyzer.send(:p_x, 99, :delay)).to eq 99.1
    end

    it 'calculates statistic' do
      analyzer = Sdb::Analyzer::PumaLogAnalyzer.from_log('./data/puma.log')
      statistic = analyzer.statistic

      expected_result = {
        total: 5,
        avg: 38.995400000000004,
        cpu_time_avg: 28.321199999999997,
        p50: 18.762999999999998,
        cpu_time_p50: 15.14,
        p90: 80.33900000000001,
        cpu_time_p90: 56.366,
        p99: 116.8862,
        cpu_time_p99: 81.071
      }

      expect(statistic).to eq expected_result
    end
  end
end
