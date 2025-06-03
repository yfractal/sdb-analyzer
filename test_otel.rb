require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/semantic_conventions'

OpenTelemetry::SDK.configure do |c|
  endpoint = ENV.fetch('OTLP_ENDPOINT', 'http://localhost:4318/v1/traces')
  puts "Using OTLP endpoint: #{endpoint}"

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: endpoint,
      )
    )
  )

  # Add console exporter for debugging
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
      OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
    )
  )

  c.resource = OpenTelemetry::SDK::Resources::Resource.create({
    OpenTelemetry::SemanticConventions::Resource::SERVICE_NAME => 'test-service',
    OpenTelemetry::SemanticConventions::Resource::SERVICE_VERSION => '1.0.0',
    OpenTelemetry::SemanticConventions::Resource::DEPLOYMENT_ENVIRONMENT => 'test'
  })
end

tracer = OpenTelemetry.tracer_provider.tracer('test-tracer')

# Create a test span
tracer.in_span('test-operation') do |span|
  span.set_attribute('test.attribute', 'test-value')
  puts "Created test span"
  sleep 1
  tracer.in_span('test-operation2') do |span|
    span.set_attribute('test.attribute2', 'test-value2')
    puts "Created test span2"
    sleep 1
  end
end

puts "Flushing traces..."
OpenTelemetry.tracer_provider.force_flush
puts "Done"
