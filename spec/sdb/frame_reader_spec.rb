# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::FrameReader do
  describe 'read' do
    describe 'reads single line' do
      it 'reads single frame' do
        data = [
          [1, 2, 18446744073709551615, 18446744073709551615]
        ]

        frames = Sdb::Analyzer::FrameReader.read(data)

        expect(frames).to eq [[1, 2]]
      end

      it 'reads 2 frames' do
        data = [
          [1, 18446744073709551615, 18446744073709551615, 2, 18446744073709551615, 18446744073709551615]
        ]

        frames = Sdb::Analyzer::FrameReader.read(data)

        expect(frames).to eq [[1], [2]]
      end
    end


    describe 'reads multiple lines' do
      it 'reads 2 line' do
        data = [
          [1, 18446744073709551615, 18446744073709551615],
          [2, 18446744073709551615, 18446744073709551615]
        ]

        frames = Sdb::Analyzer::FrameReader.read(data)

        expect(frames).to eq [[1], [2]]
      end

      it 'reads different seperator category' do
        data = [
          [1, 18446744073709551615],
          [18446744073709551615, 2, 18446744073709551615, 18446744073709551615]
        ]

        frames = Sdb::Analyzer::FrameReader.read(data)

        expect(frames).to eq [[1], [2]]
      end

      it 'reads reads different seperator category' do
        data = [
          [1],
          [18446744073709551615, 18446744073709551615, 2, 18446744073709551615, 18446744073709551615]
        ]

        frames = Sdb::Analyzer::FrameReader.read(data)

        expect(frames).to eq [[1], [2]]
      end
    end

    describe 'it reads frame log into frame object' do
      it 'reads single frame' do
        data = [
          [1, 2, 18446744073709551615, 18446744073709551615]
        ]

        frames = Sdb::Analyzer::FrameReader.read(data)

        expect(frames).to eq [[1, 2]]
      end

      it 'reads 2 frames' do
        data = [
          [0, 1739367653956162, 281473714183720, 281473714361760, 18446744073709551615, 18446744073709551615]
        ]

        frames = Sdb::Analyzer::FrameReader.read_raw_frames(data)

        expect(frames[0].trace_id).to eq 0
        expect(frames[0].ts).to eq 1739367653956162
        expect(frames[0].iseqs).to eq [281473714361760, 281473714183720]
      end
    end
  end
end
