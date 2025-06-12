# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::FrameTable do
  it 'finds frames' do
    frames, _ = Sdb::Analyzer::LogReader.read("./spec/data/stack_frames.log")
    frame_table = Sdb::Analyzer::FrameTable.new(frames)

    request_table = Sdb::Analyzer::RequestTable.new([
      '2025-06-11 09:48:43.706695  [INFO] [35825][request][SDB][application][rails]: {"trace_id":"dd625444ab783fea46ae00e8052b54d0","thread_id":42060071,"controller":"Api::V3::TopicsController","action":"index","path":"/api/v3/topics"}',
      '2025-06-11 09:48:43.8026    [INFO] [35825][request][SDB][application][puma]: {"trace_id":"dd625444ab783fea46ae00e8052b54d0","thread_id":42060071,"start_ts":1749606523700140,"end_ts":1749606523802575,"cpu_time_ms":68.49899999999987,"status":200}'
    ])

    request = request_table.requests[0]
    frames = frame_table.find_frames(request)
    expect(frames.count).to be > 0

    frames.each do |frame|
      expect(frame.process_id).to eq 35825
      expect(frame.thread_id).to eq 42060071
      expect(frame.ts).to be >= request.start_ts
      expect(frame.ts).to be <= request.end_ts
    end
  end
end