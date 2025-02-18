require 'ruby-graphviz'

module Sdb
  module Analyzer
    module Presenters
      class ImagePresenter
        def initialize(frame_analyzer)
          @frame_analyzer = frame_analyzer
        end

        def render(file_name)
          graph = GraphViz.new( :G, :type => :digraph )

          @total = @frame_analyzer.roots.map {|root| root.duration }.sum.to_f

          @fake_generation = 0

          @frame_analyzer.roots.each do |root|
            graph[:bgcolor] = '#253238'
            meta = {}
            meta[:frame_count] = 0
            meta[:iseqs_count] = 0
            meta[:c_iseqs_count] = 0
            meta[:no_symbols_count] = 0
            meta[:duration] = root.duration
            meta[:captured_duration_count] = 0

            render_iseq_node(graph, root, meta)
          end

          graph.output( :png => file_name )

          graph
        end

        def render_iseq_node(graph, iseq_node, meta)
          meta[:iseqs_count] += 1

          if iseq_node.children.count == 0
            meta[:frame_count] += 1
          end

          method, file, line_no = iseq_node.iseq.name, iseq_node.iseq.path_or_module, iseq_node.iseq.first_lineno

          if method == nil
            meta[:no_symbols_count] += 1
            method = iseq_node.iseq.addr.to_s
          end

          file ||= ""
          line_no ||= 0

          if file.include?("/") && !file.split("/")[-3..-1].nil?
            label = "#{method}(#{file.split("/")[-3..-1].join("/")}:#{line_no})"
          else
            label = "#{method}(#{file}:#{line_no})"
          end

          node = graph.add_nodes(iseq_node.iseq.to_s + "-#{@fake_generation}", label: label, color: '#2e95d3', fontcolor: '#2e95d3')

          @fake_generation += 1
          iseq_node.children.each do |child|
            duration = child.duration
            byebug if duration == nil || @total == nil
            percentage = (duration / @total * 100).round(2)
            label = "#{duration/1000.0}ms (#{percentage}%)"
            child = render_iseq_node(graph, child, meta)
            graph.add_edges(node, child, label: label, color: '#00a67d', fontcolor: '#00a67d') if child
          end

          node
        end
      end
    end
  end
end
