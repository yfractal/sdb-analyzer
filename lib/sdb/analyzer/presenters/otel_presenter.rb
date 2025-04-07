require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/semantic_conventions'
require 'securerandom'

OpenTelemetry::SDK.configure do |c|
  # Configure the OTLP exporter for Datadog
  endpoint = ENV.fetch('OTLP_ENDPOINT', 'http://localhost:4318/v1/traces')

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: endpoint,
      )
    )
  )

  c.service_name = ENV.fetch('DD_SERVICE', 'sdb-analyzer')

  # Set resource attributes
  c.resource = OpenTelemetry::SDK::Resources::Resource.create({
    OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => ENV.fetch('OTEL_SERVICE', 'sdb-analyzer'),
    OpenTelemetry::SemanticConventions::Resource::SERVICE_VERSION => ENV.fetch('OTEL_VERSION', '1.0.0'),
    OpenTelemetry::SemanticConventions::Resource::DEPLOYMENT_ENVIRONMENT => ENV.fetch('OTEL_ENV', 'development')
  })
end

module Sdb
  module Analyzer
    module Presenters
      class OtelPresenter
        def initialize(roots)
          @roots = roots
          @tracer = OpenTelemetry.tracer_provider.tracer('sdb_analyzer')
          @total = 0
        end

        def render
          @total = @roots.map(&:duration).sum.to_f

          # Create a parent span for the entire profile
          @tracer.in_span("Ruby Profile", attributes: {
            'profiler.name' => 'ruby_profile',
            'profiler.type' => 'cpu_profile'
          }) do |parent_span|
            context = OpenTelemetry::Trace.context_with_span(parent_span)
            @roots.each do |root|
              process_iseq_node(root, context)
            end
          end

          OpenTelemetry.tracer_provider.force_flush
        end

        private

        def process_iseq_node(iseq_node, parent_context)
          method = iseq_node.iseq.name || iseq_node.iseq.addr.to_s
          file = iseq_node.iseq.path_or_module || ""
          line_no = iseq_node.iseq.first_lineno || 0
          duration = iseq_node.duration
          return if duration == 0
          percentage = (duration / @total * 100).round(2)

          span_name = if file.include?("/") && !file.split("/")[-3..-1].nil?
            "#{method}(#{file.split("/")[-3..-1].join("/")}:#{line_no})"
          else
            "#{method}(#{file}:#{line_no})"
          end

          attributes = {
            'code.method' => method,
            'code.filepath' => file,
            'code.lineno' => line_no.to_s,
            'execution.duration_ms' => duration / 1000.0,
            'execution.percentage' => percentage,
            'execution.children_count' => iseq_node.children.count,
            'span.kind' => 'internal',
            'language' => 'ruby'
          }

          OpenTelemetry::Context.with_current(parent_context) do
            @tracer.in_span(span_name, attributes: attributes) do |span|
              new_context = OpenTelemetry::Trace.context_with_span(span)
              iseq_node.children.each do |child|
                process_iseq_node(child, new_context)
              end
            end
          end
        end
      end
    end
  end
end
