# frozen_string_literal: true

RSpec.describe Sdb::Analyzer do
  it "has a version number" do
    expect(Sdb::Analyzer::VERSION).not_to be nil
  end

   # TODO: write tests when walker is stable
  context 'FrameWalker Demo' do
    # it 'works roda frames' do
    #   walker = Sdb::FrameWalker::Walker.new('./spec/data/frames-roda.log', './spec/data/methods-table-roda.log')
    #   walker.walk
    #   walker.draw('roda.png')

    #   puts 'Please check roda.png'
    # end

    # it 'rails-api' do
    #   walker = Sdb::FrameWalker::Walker.new('./spec/data/frames-rails-api.log', './spec/data/methods-table-rails-api.log')
    #   walker.walk
    #   walker.draw('rails-api.png')

    #   puts 'please check rails-api.png'
    # end
    it 'draws graph' do
      walker = Sdb::FrameWalker::Walker.new('sdb.log')
      walker.walk(123456)
      walker.draw('http-request.png')

      puts 'please check http-request.png'
    end

    it 'draws http' do
      walker = Sdb::FrameWalker::Walker.new('sdb-http.log')
      walker.walk(123456)
      walker.draw('http-request.png')

      puts 'please check http-request.png'
    end
  end
end
