# frozen_string_literal: true

RSpec.describe Sdb::Analyzer::RequestTable do
  it 'read lines into request' do
    lines = [
      '2025-06-10 22:52:39.030505  [INFO] [45213][request][SDB][application][rails]: {"trace_id":"e37f1bf207fd847ee417a65022fa900a","controller":"Api::V3::NodesController","action":"index","path":"/api/v3/nodes"}',
      '2025-06-10 22:52:39.07651   [INFO] [45213][request][SDB][application][puma]: {"trace_id":"e37f1bf207fd847ee417a65022fa900a","thread_id":41629390,"start_ts":1749567159025097,"end_ts":1749567159076486,"cpu_time_ms":31.066000000000038,"status":200}',
      '2025-06-10 22:52:39.078349  [INFO] [45213][request][SDB][application][rails]: {"trace_id":"4a93bdbbf53d80137430110714d8667b","controller":"Api::V3::RootController","action":"hello","path":"/api/v3/hello"}',
      '2025-06-10 22:52:39.080268  [INFO] [45213][request][SDB][application][puma]: {"trace_id":"4a93bdbbf53d80137430110714d8667b","thread_id":41629390,"start_ts":1.749567159077485e+15,"end_ts":1749567159080249,"cpu_time_ms":2.19899999999984,"status":401}'
    ]

    request_table = Sdb::Analyzer::RequestTable.new(lines)

    expect(request_table.requests.count).to eq 2

    expect(request_table.requests[0].trace_id).to eq "e37f1bf207fd847ee417a65022fa900a"
    expect(request_table.requests[0].controller).to eq "Api::V3::NodesController"
    expect(request_table.requests[0].action).to eq "index"
    expect(request_table.requests[0].path).to eq "/api/v3/nodes"
    expect(request_table.requests[0].thread_id).to eq 41629390
    expect(request_table.requests[0].start_ts).to eq 1749567159025097
    expect(request_table.requests[0].end_ts).to eq 1749567159076486
    expect(request_table.requests[0].cpu_time_ms).to eq 31.066000000000038
    expect(request_table.requests[0].status).to eq 200
    expect(request_table.requests[0].process_id).to eq 45213

    expect(request_table.requests[1].trace_id).to eq "4a93bdbbf53d80137430110714d8667b"
    expect(request_table.requests[1].controller).to eq "Api::V3::RootController"
    expect(request_table.requests[1].action).to eq "hello"
    expect(request_table.requests[1].path).to eq "/api/v3/hello"
    expect(request_table.requests[1].thread_id).to eq 41629390
    expect(request_table.requests[1].start_ts).to eq 1749567159077485
    expect(request_table.requests[1].end_ts).to eq 1749567159080249
    expect(request_table.requests[1].cpu_time_ms).to eq 2.19899999999984
    expect(request_table.requests[1].status).to eq 401
    expect(request_table.requests[1].process_id).to eq 45213
  end
end
