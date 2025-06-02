require "sdb/analyzer"
require 'byebug'

analyzer = Sdb::Analyzer::Core.new('./spec/data/sdb.log')
roots = analyzer.analyze(11111122)

presenter = Sdb::Analyzer::Presenters::ImagePresenter.new(roots)
presenter.render('demo.png')

puts 'Please check demo.png'
