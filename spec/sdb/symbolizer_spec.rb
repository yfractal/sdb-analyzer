RSpec.describe Sdb::Analyzer::Symbolizer do
  before do
    @log_line = '2025-02-13 01:45:28.279442089 [INFO] [time] uptime=584000000, clock_time=1739411128279420'
    @time_converter = Sdb::Analyzer::TimeConverter.from_log_line(@log_line)
    @symbol_table = Sdb::Analyzer::SymbolsTable.from_log('./spec/data/symbols_gc_compact.log')
    @symbolizer = described_class.new(@symbol_table, @time_converter)
  end

  it 'translates iseqs' do
    raw_frames = [
      [0, 1739411128341814, 281473430970480, 281473431723480, 281473431723280, 281473431723040, 281473431722960, 281473431722880, 281473431722280, 281473488682200, 281473431722520, 281473431561800, 0, 18446744073709551615, 18446744073709551615]
    ]

    frames = Sdb::Analyzer::FrameReader.read_raw_frames(raw_frames)
    iseq = @symbolizer.translate(frames[0])[5]

    # {"ts": 583433152, "ts_ns": 583433152598, "first_lineno": 25, "name": "fffffff", "path": "\u0005(\ufffd ", "iseq_addr": 281473431722880, "to_addr": 0, "type": 0}
    expect(iseq.addr).to eq 281473431722880
    expect(iseq.name).to eq 'fffffff'
    expect(iseq.ts).to eq 583433152
  end

  it 'translates the iseq after gc compact happened' do
    # {"ts": 583433152, "ts_ns": 583433152598, "first_lineno": 25, "name": "fffffff", "path": "\u0005(\ufffd ", "iseq_addr": 281473431722880, "to_addr": 0, "type": 0}
    # {"ts": 585125840, "ts_ns": 585125840933, "first_lineno": 0, "name": "", "path": "", "iseq_addr": 281473431722880, "to_addr": 281473432083760, "type": 7}
    # 

    raw_frames = [
      [0, 1739411129426798, 281473430970480, 281473432086080, 281473432085400, 281473432084760, 281473432083880, 281473432083760, 281473432082000, 281473488682200, 281473431722520, 281473431561800, 0, 18446744073709551615, 18446744073709551615]
    ]

    frames = Sdb::Analyzer::FrameReader.read_raw_frames(raw_frames)
    iseq = @symbolizer.translate(frames[0])[5]

    expect(iseq.addr).to eq 281473432083760 # the new address
    expect(iseq.name).to eq 'fffffff'
    expect(iseq.ts).to eq 585125840 # the new ts
  end
end
