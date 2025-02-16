# Sdb::Analyzer

## Architecture

               Presenter
FrameAnalyzer, Symbolizer, PumaLogAnalyzer

- FrameAnalyzer
  Coverts SDB raw frames to function call graph for presenter.
  Which includes FrameReader and FrameWalker.
- Symbolizer
- PumaLogAnalyzer
