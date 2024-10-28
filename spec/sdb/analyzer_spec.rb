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

  it 'new iseq' do
    walker = Sdb::FrameWalker::Walker.new('data/traces.log', 'data/iseqs.log')
    walker.walk(11111116)
    walker.draw('http-requestx.png')

    puts 'please check http-requestx.png'
  end

  it 'homeland' do
    walker = Sdb::FrameWalker::Walker.new('./data/sdb-homeland.log', './data/iseqs-homeland.log')
    walker.walk(1111113)
    walker.draw('homeland.png')

    puts 'please check homeland.png'
  end

  it 'draws roda request' do
    walker = Sdb::FrameWalker::Walker.new('./data/sdb-roda.log', './data/iseqs-roda.log')
    walker.walk(1111115)
    walker.draw('roda.png')

    puts 'please check roda.png'
  end

  it 'draws rails-api request' do
    walker = Sdb::FrameWalker::Walker.new('./data/sdb-rails-api.log', './data/iseqs-rails-api.log')
    walker.walk(1111114)
    walker.draw('images/rails-api.png')

    puts 'please check images/rails-api.png'
  end

  it 'draws homeland request' do
    walker = Sdb::FrameWalker::Walker.new('./data/sdb-homeland.log', './data/iseqs-homeland.log')
    walker.walk(1111113)
    walker.draw('images/homeland.png')

    puts 'please check images/homeland.png'
  end

  it 'handles bootsnap' do
    walker = Sdb::FrameWalker::Walker.new('./data/sdb-homeland-bootsnap.log', './data/iseqs-homeland-bootsnap.log')
    walker.walk(1111112)
    walker.draw('images/homeland-bootsnap.png')

    puts 'please check images/homeland-bootsnap.png'
  end

  it 'handles cfunc' do
    walker = Sdb::FrameWalker::Walker.new('./data/sdb-cfunc.log', './data/iseqs-cfunc.log')
    walker.walk(1111112)
    walker.draw('images/homeland-with-cfunc.png')
    puts 'please check images/homeland-with-cfunc.png'
  end
end
