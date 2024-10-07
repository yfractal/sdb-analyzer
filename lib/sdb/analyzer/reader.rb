
module Sdb
  class Reader
    def initialize(file, type='ebpf')
      @file = File.new(file)
      @type = type
    end

    def read
      do_read(@file, @type)
    end

    private
    def do_read(file, type)
      rows = []

      # line example: pid=24079, tgid=23630, name=puma srv tp 001, start_ts=35734583193681, end_ts=35734590012666
      file.each_line do |line|
        items = line.strip.split(', ')
        data = {}
        items.each do |item|
          k, v = item.split('=')

          v_i = v.to_i
          if v_i != 0 && v != '0'
            v = v_i
          end          

          data[k] = v
        end
        rows << data
      end

      rows
    end
  end
end