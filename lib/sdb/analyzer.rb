# frozen_string_literal: true

require_relative "analyzer/version"
require_relative "analyzer/exporter"
require_relative "analyzer/frame_reader"
require_relative "analyzer/frame_walker"
require_relative "analyzer/frame_analyzer"
require_relative "analyzer/puma_log_analyzer"
require_relative "analyzer/reader"
require_relative "analyzer/helper"
require_relative "analyzer/symbols_table"
require_relative "analyzer/time_converter"
require_relative "analyzer/symbolizer"
require_relative "analyzer/presenters/image_presenter"

module Sdb
  module Analyzer
    class Error < StandardError; end
  end
end
