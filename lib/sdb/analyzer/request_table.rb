# frozen_string_literal: true

require 'json'

module Sdb
  module Analyzer
    class RequestTable

      Request = Struct.new(:trace_id, :controller, :action, :path, :thread_id, :start_ts, :end_ts, :cpu_time_ms, :status, :process_id)

      attr_reader :requests

      def initialize(lines)
        @lines = lines
        @requests = []
        raw_data = {}

        lines.each do |line|
          tag, raw_content = line.split(': ')
          match = tag.match(/\[INFO\]\s*\[(\d+)\]/)
          process_id = match[1].to_i if match

          content = JSON.parse(raw_content)
          raw_data[content['trace_id']] ||= {}
          raw_data[content['trace_id']].merge!(content)
          raw_data[content['trace_id']]['process_id'] = process_id
        end

        raw_data.each do |trace_id, data|
          @requests << Request.new(trace_id, data['controller'], data['action'], data['path'], data['thread_id'], data['start_ts'], data['end_ts'], data['cpu_time_ms'], data['status'], data['process_id'])
        end
      end
    end
  end
end
