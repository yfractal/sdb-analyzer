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
  end
end
