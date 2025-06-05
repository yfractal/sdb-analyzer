module Sdb
  module Analyzer
    module Presenters
      class SingleRequestFlamegraphPresenter
        TEMPLATE = 'single_request_flamegraph_template.html'

        def initialize(roots)
          @roots = roots
        end

        def render
          rows = []

          @roots.each do |root|
            depth = 0
            collect_rows(rows, depth, root)
          end

          generate_html(rows)
        end

        private

        def collect_rows(rows, depth, node)
          rows[depth] ||= []

          label = if node.iseq.path.split("/").length > 4
            "#{node.iseq.label} (#{node.iseq.path.split("/")[-4..].join("/")})"
          else
            node.iseq.label
          end

          duration, certainty = node.duration, 'certain'

          rows[depth] << [label, node.ts, duration, "bar0", certainty]
          node.children.each do |child|
            collect_rows(rows, depth + 1, child)
          end
        end

        def generate_html(rows)
          # Convert rows to JavaScript array format
          js_rows = rows.map do |row|
            if row
              row_items = row.map { |item| "[#{item.map(&:inspect).join(', ')}]" }.join(', ')
              "[#{row_items}]"
            else
              "[]"
            end
          end.join(",\n        ")

          # Read template file
          template_path = File.join(File.dirname(__FILE__), TEMPLATE)
          template = File.read(template_path)

          # Replace placeholder with data
          template
            .gsub('{{PROFILE_DATA}}', js_rows)
            .gsub('{{SAMPLING_INTERVAL_MS}}', 1000.to_s) # todo: read the sampling interval from SDB log's header
        end
      end
    end
  end
end
