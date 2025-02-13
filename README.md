# Sdb::Analyzer

## Architecture

The Sdb::Analyzer works like raw frames -> frame-reader -> frame-walker -> presenter.

The frame-reader coverts raw frames to frames and the frame-walker coverts the frames to call graph and then presenter is for converting it to image or traces.

Symbolizer is used for converting a Iseq address to function info.
