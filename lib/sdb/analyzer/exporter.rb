require 'json'

module Sdb
  class Exporter
    def initialize(rows, type = 'perfetto_trace')
      @rows = rows
      @type = type
    end

    def export
      do_export(@rows, @type)
    end

    private
    def do_export(rows, type)
      output_rows = []
      thread_id_to_thread_name = {}
      start_ts = rows[0]['start_ts']
      rows.each do |row|
        thread_id = row['pid']

        if !thread_id_to_thread_name[thread_id]
          thread_id_to_thread_name[thread_id] = true
          output_rows << {"ph": "M", "pid": row['pid'], "tid": row['tgid'], "name": "thread_name", "args": {"name": row['name']}}
          output_rows << {"ph": "E", "pid": row['pid'], "tid": row['tgid'], "ts": covert_ts(row['start_ts'] - start_ts)}
        end

        output_rows << {"ph": "B", "pid": row['pid'], "tid":  row['tgid'], "ts": covert_ts(row['start_ts'] - start_ts), "name": "oncpu"}
        output_rows << {"ph": "E", "pid": row['pid'], "tid":  row['tgid'], "ts": covert_ts(row['end_ts'] - start_ts)}
      end

      output_rows.to_json
    end

    def covert_ts(ts)
      sprintf("%0.06f", ts.to_f / 1_000).to_f
    end
  end
end
