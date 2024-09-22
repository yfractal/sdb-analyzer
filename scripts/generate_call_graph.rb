require 'sdb/analyzer'
require 'byebug'

# Usage example: bundle exec ruby scripts/generate_call_graph.rb tmp.log 777005 server.png

file = ARGV[0]
trace_id = ARGV[1].to_i
output_file = ARGV[2] || 'output.png'

walker = Sdb::FrameWalker::Walker.new(file)
walker.walk(trace_id)
walker.draw(output_file)
