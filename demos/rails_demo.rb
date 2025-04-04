require "sdb/analyzer"
require 'byebug'


analyzer = Sdb::Analyzer::Core.new('./demos/rails-demo/sdb.log', './demos/rails-demo/symbols.log')
roots = analyzer.analyze(10009)

presenter = Sdb::Analyzer::Presenters::ImagePresenter.new(roots)
presenter.render('rails_demo.png')

puts 'Please check rails_demo.png'