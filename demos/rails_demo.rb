require "sdb/analyzer"
require 'byebug'

time_converter, frames = Sdb::Analyzer::LogReader.read_sdb_log('./demos/rails-demo/sdb.log', 10009)
symbol_table = Sdb::Analyzer::SymbolsTable.from_log('./demos/rails-demo/symbols.log')
symbolizer = Sdb::Analyzer::Symbolizer.new(symbol_table, time_converter)

frame_analyzer = Sdb::Analyzer::FrameAnalyzer.new(frames, symbolizer)
frame_analyzer.walk

presenter = Sdb::Analyzer::Presenters::ImagePresenter.new(frame_analyzer)

presenter.render('rails_demo.png')

puts 'Please check rails_demo.png'
