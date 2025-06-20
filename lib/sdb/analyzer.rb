# frozen_string_literal: true

require_relative "analyzer/version"
require_relative "analyzer/disambiguator"
require_relative "analyzer/frame_reader"
require_relative "analyzer/frame_analyzer"
require_relative "analyzer/log_reader"
require_relative "analyzer/puma_log_analyzer"
require_relative "analyzer/request_table"
require_relative "analyzer/symbols_table"
require_relative "analyzer/frame_table"
require_relative "analyzer/symbol_reader"
require_relative "analyzer/symbolizer"
require_relative "analyzer/symbolizer2"
require_relative "analyzer/time_converter"
require_relative "analyzer/presenters/image_presenter"
require_relative "analyzer/presenters/otel_presenter"
require_relative "analyzer/presenters/html_presenter"
require_relative "analyzer/presenters/single_request_flamegraph_presenter"
require_relative "analyzer/web"

module Sdb
  module Analyzer
    class Error < StandardError; end
    class Core
      attr_reader :request_table

      def initialize(sdb_log)
        frames, @symbols, requests = Sdb::Analyzer::LogReader.read(sdb_log)
        @symbolizer = Sdb::Analyzer::Symbolizer2.new(@symbols)
        @frame_table = Sdb::Analyzer::FrameTable.new(frames)
        @request_table = Sdb::Analyzer::RequestTable.new(requests)
      end

      # def initialize(sdb_log, symbols_log)
      #   @time_converter, @frames = Sdb::Analyzer::LogReader.read_sdb_log(sdb_log)
      #   @symbol_table = Sdb::Analyzer::SymbolsTable.from_log(symbols_log)
      #   @symbolizer = Sdb::Analyzer::Symbolizer.new(@symbol_table, @time_converter)
      # end

      def analyze(request)
        frames = @frame_table.find_frames(request)

        frame_analyzer = Sdb::Analyzer::FrameAnalyzer.new(request.process_id, frames, @symbolizer)

        frame_analyzer.walk
      end
    end
  end
end
