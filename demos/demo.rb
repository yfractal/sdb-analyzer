require "sdb/analyzer"
require 'byebug'

analyzer = Sdb::Analyzer::Core.new('./spec/data/sdb.log')
request = analyzer.request_table.requests.first
roots = analyzer.analyze(request)

# presenter = Sdb::Analyzer::Presenters::ImagePresenter.new(roots)
# presenter.render('./demos/demo-full.png')

disambiguator = Sdb::Analyzer::Disambiguator.new(roots)
disambiguated_roots = disambiguator.disambiguate

presenter = Sdb::Analyzer::Presenters::SingleRequestFlamegraphPresenter.new(disambiguated_roots)
html_content = presenter.render
File.write('./demos/demo.html', html_content)
