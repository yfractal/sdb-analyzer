require 'sdb/analyzer'
require 'byebug'

file = ARGV[0]
output_file = ARGV[1]
Sdb::FrameWalker::Helper.compact(file, output_file)