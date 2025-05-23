# frozen_string_literal: true

require_relative "analyzer/version"
require_relative "analyzer/frame_reader"
require_relative "analyzer/frame_analyzer"
require_relative "analyzer/puma_log_analyzer"
require_relative "analyzer/symbols_table"
require_relative "analyzer/time_converter"
require_relative "analyzer/symbolizer"
require_relative "analyzer/presenters/image_presenter"
require_relative "analyzer/log_reader"

module Sdb
  module Analyzer
    class Error < StandardError; end
    class Core
      def initialize(sdb_log, symbols_log)
        @time_converter, @frames = Sdb::Analyzer::LogReader.read_sdb_log(sdb_log)
        @symbol_table = Sdb::Analyzer::SymbolsTable.from_log(symbols_log)
        @symbolizer = Sdb::Analyzer::Symbolizer.new(@symbol_table, @time_converter)
      end

      def analyze(trace_id)
        frames = @frames.select { |frame| frame.trace_id == trace_id }
        frame_analyzer = Sdb::Analyzer::FrameAnalyzer.new(frames, @symbolizer)

        frame_analyzer.walk
      end
    end
  end
end
