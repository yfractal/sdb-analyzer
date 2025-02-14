# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::FrameAnalyzer do
  it 'builds simple call graph' do
    frame1 = Sdb::Analyzer::FrameReader::Frame.new(0, 0, [11, 22, 33])
    frame2 = Sdb::Analyzer::FrameReader::Frame.new(0, 10, [11, 22, 33])

    frame_reader = described_class.new([frame1, frame2])
    frame_reader.walk

    expect(frame_reader.roots.count).to eq 1

    root = frame_reader.roots[0]
    expect(root.duration).to eq 10
    expect(root.ts).to eq 0

    expect(root.iseq).to eq 11
    expect(root.children[0].iseq).to eq 22
    expect(root.children[0].children[0].iseq).to eq 33

    expect(root.children[0].parent.iseq).to eq 11
  end

  it 'handles children' do
    frame1 = Sdb::Analyzer::FrameReader::Frame.new(0, 0, [11, 22, 33])
    frame2 = Sdb::Analyzer::FrameReader::Frame.new(0, 10, [11, 44])

    frame_reader = described_class.new([frame1, frame2])
    frame_reader.walk

    root = frame_reader.roots[0]
    expect(root.children[0].iseq).to eq 22
    expect(root.children[1].iseq).to eq 44
  end

  it 'handles new call' do
    frame1 = Sdb::Analyzer::FrameReader::Frame.new(0, 0, [11, 22, 33])
    frame2 = Sdb::Analyzer::FrameReader::Frame.new(0, 10, [11, 22, 33, 44])

    frame_reader = described_class.new([frame1, frame2])
    frame_reader.walk

    root = frame_reader.roots[0]
    expect(root.iseq).to eq 11
    expect(root.children[0].iseq).to eq 22
    expect(root.children[0].children[0].iseq).to eq 33
    expect(root.children[0].children[0].children[0].iseq).to eq 44

    expect(root.children[0].children[0].duration).to eq 10
    expect(root.children[0].children[0].children[0].duration).to eq 0
  end

  it 'handles multiple roots' do
    frame1 = Sdb::Analyzer::FrameReader::Frame.new(0, 0, [11, 22, 33])
    frame2 = Sdb::Analyzer::FrameReader::Frame.new(0, 10, [111, 222, 333])

    frame_reader = described_class.new([frame1, frame2])
    frame_reader.walk

    expect(frame_reader.roots.count).to eq 2

    root = frame_reader.roots[0]
    expect(root.iseq).to eq 11
    expect(root.children[0].iseq).to eq 22
    expect(root.children[0].children[0].iseq).to eq 33

    root1 = frame_reader.roots[1]
    expect(root1.iseq).to eq 111
    expect(root1.children[0].iseq).to eq 222
    expect(root1.children[0].children[0].iseq).to eq 333
  end
end
