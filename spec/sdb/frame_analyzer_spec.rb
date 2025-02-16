# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::FrameAnalyzer do
  describe '#walk' do
    let(:symbolizer) do
      symbols_data =  [
        {'ts' => 1, 'first_lineno' => 1, 'name' => 'func11', 'path' => 'some-path', 'iseq_addr' => 11, 'to_addr' => 0, 'type' => 0},
        {'ts' => 2, 'first_lineno' => 2, 'name' => 'func22', 'path' => 'some-path', 'iseq_addr' => 22, 'to_addr' => 0, 'type' => 0},
        {'ts' => 3, 'first_lineno' => 3, 'name' => 'func33', 'path' => 'some-path', 'iseq_addr' => 33, 'to_addr' => 0, 'type' => 0},
        {'ts' => 4, 'first_lineno' => 0, 'name' => '', 'path' => '', 'iseq_addr' => 11, 'to_addr' => 55, 'type' => 7},
      ]
  
      table = Sdb::Analyzer::SymbolsTable.new
      symbols_data.each { |d| table.read_line(d) }

      log_line = '2025-02-13 01:45:28.279442089 [INFO] [time] uptime=0, clock_time=0'
      time_converter = Sdb::Analyzer::TimeConverter.from_log(log_line)

      Sdb::Analyzer::Symbolizer.new(table, time_converter)
    end

    it 'simple call graph' do
      frames = [
        Sdb::Analyzer::FrameReader::Frame.new(0, 11, [11, 22, 33]),
        Sdb::Analyzer::FrameReader::Frame.new(0, 21, [11, 22, 33])
      ]

      analyzer = described_class.new(frames, symbolizer)
      analyzer.walk

      expect(analyzer.roots.count).to eq 1
  
      root = analyzer.roots[0]
      expect(root.duration).to eq 10
      expect(root.ts).to eq 11
  
      expect(root.iseq.addr).to eq 11
      expect(root.children[0].iseq.addr).to eq 22
      expect(root.children[0].children[0].iseq.addr).to eq 33
  
      expect(root.children[0].parent.iseq.addr).to eq 11
    end

    it 'iseq has been moved to other place' do
      #  {'ts' => 4, 'first_lineno' => 0, 'name' => '', 'path' => '', 'iseq_addr' => 11, 'to_addr' => 55, 'type' => 7}
      frames = [
        Sdb::Analyzer::FrameReader::Frame.new(0, 11, [11, 22, 33]),
        Sdb::Analyzer::FrameReader::Frame.new(0, 21, [55, 22, 33])
      ]

      analyzer = described_class.new(frames, symbolizer)
      analyzer.walk

      expect(analyzer.roots.count).to eq 1
  
      root = analyzer.roots[0]
      expect(root.duration).to eq 10
      expect(root.ts).to eq 11
  
      expect(root.iseq.addr).to eq 11
      expect(root.children[0].iseq.addr).to eq 22
      expect(root.children[0].children[0].iseq.addr).to eq 33
  
      expect(root.children[0].parent.iseq.addr).to eq 11
    end

    it 'new func' do
      frames = [
        Sdb::Analyzer::FrameReader::Frame.new(0, 0, [11, 22, 33]),
        Sdb::Analyzer::FrameReader::Frame.new(0, 10, [11, 22, 33, 44])
      ]

      analyzer = described_class.new(frames, symbolizer)
      analyzer.walk

      root = analyzer.roots[0]
      expect(root.children[0].children[0].iseq.addr).to eq 33
      expect(root.children[0].children[0].children[0].iseq.addr).to eq 44
    end

    it 'with children' do
      frames = [
        Sdb::Analyzer::FrameReader::Frame.new(0, 0, [11, 22, 33]),
        Sdb::Analyzer::FrameReader::Frame.new(0, 10, [11, 44])
      ]

      analyzer = described_class.new(frames, symbolizer)
      analyzer.walk

      root = analyzer.roots[0]

      # TODO: a iseq doesn't have symbols information ............
      expect(root.children[0].iseq.addr).to eq 22
      expect(root.children[1].iseq.addr).to eq 44

      expect(root.children[1].iseq.type).to eq :nil
      expect(root.children[1].iseq.name).to eq nil
    end

    it 'no symbols iseq addr' do
      frames = [
        Sdb::Analyzer::FrameReader::Frame.new(0, 0, [44, 11]),
        Sdb::Analyzer::FrameReader::Frame.new(0, 10, [44, 22])
      ]

      analyzer = described_class.new(frames, symbolizer)
      analyzer.walk

      root = analyzer.roots[0]
      expect(root.duration).to eq 10
      expect(root.children.count).to eq 2
    end

    it 'multiple roots' do
      frames = [
        Sdb::Analyzer::FrameReader::Frame.new(0, 0, [11, 22, 33]),
        Sdb::Analyzer::FrameReader::Frame.new(0, 10, [111, 222, 333])
      ]

      analyzer = described_class.new(frames, symbolizer)
      analyzer.walk

      expect(analyzer.roots.count).to eq 2
  
      root = analyzer.roots[0]
      expect(root.iseq.addr).to eq 11
      expect(root.children[0].iseq.addr).to eq 22
      expect(root.children[0].children[0].iseq.addr).to eq 33
  
      root1 = analyzer.roots[1]
      expect(root1.iseq.addr).to eq 111
      expect(root1.children[0].iseq.addr).to eq 222
      expect(root1.children[0].children[0].iseq.addr).to eq 333
    end
  end
end
