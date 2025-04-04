RSpec.describe Sdb::Analyzer::Presenters::ImagePresenter do
  def node_attributes(node)
    node.instance_variable_get('@node_attributes').data.to_h
  end

  def node_label(node)
    node_attributes(node)['label'].to_s
  end

  it 'raw graph' do
    @log_line = '2025-02-13 01:45:28.279442089 [INFO] [time] uptime=584000000, clock_time=1739411128279420'
    @time_converter = Sdb::Analyzer::TimeConverter.from_log_line(@log_line)
    @symbol_table = Sdb::Analyzer::SymbolsTable.from_log('./spec/data/symbols_gc_compact.log')

    symbolizer = Sdb::Analyzer::Symbolizer.new(@symbol_table, @time_converter)

    raw_frames = [
      [0, 1739411128341814, 281473430970480, 281473431723480, 281473431723280, 281473431723040, 281473431722960, 281473431722880, 281473431722280, 281473488682200, 281473431722520, 281473431561800, 0, 18446744073709551615, 18446744073709551615],
      [0, 1739411128341820, 281473430970480, 281473431723480, 281473431723280, 281473431723040, 281473431722960, 281473431722880, 281473431722280, 281473488682200, 281473431722520, 281473431561800, 0, 18446744073709551615, 18446744073709551615]
    ]

    frames = Sdb::Analyzer::FrameReader.read_v2(raw_frames)
    frame_analyzer = Sdb::Analyzer::FrameAnalyzer.new(frames, symbolizer)
    frame_analyzer.walk

    presenter = described_class.new(frame_analyzer)
    graph = presenter.render('tmp.png')
    puts 'You could check the generated image tmp.png.'

    nodes_ids = graph.enumerate_nodes

    node = graph.find_node(nodes_ids[-1])
    label = node_label(node)
    expect(label).to include '281473430970480' # haven't captured its symbol...

    node = graph.find_node(nodes_ids[-2])
    label = node_label(node)
    expect(label).to include 'xxxx'
  end
end
