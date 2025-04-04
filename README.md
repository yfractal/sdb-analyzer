# Sdb::Analyzer

- FrameAnalyzer
  read frame into calling graph with latency
  - FrameReader
    SDB writes multiple frames in one line, FrameReader splits those lines.
  - Symbolizer
    - TimeConverter
      eBPF only use the `bpf_ktime_get_ns`, which is the time in nanoseconds since system boot,
      but in a program, we can only get real-world timestamp easily,
      the TimeConverter is used for conversion
    - SymbolsTable
      - reads symbol data
      - find iseq from address and ts(we need to consider gc move, so we need the ts)
