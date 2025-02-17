require "sdb/analyzer"
require 'byebug'

frames = Sdb::Analyzer::LogReader.read_sdb_log('./demos/rails-demo/sdb.log')