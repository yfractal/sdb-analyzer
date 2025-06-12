require 'rack'
require 'erb'
require 'json'
require 'digest'

module Sdb
  module Analyzer
    class Web
      # Rack application entry point
      def self.call(env)
        new.call(env)
      end

      def call(env)
        request = Rack::Request.new(env)

        case request.path_info
        when '/', '/dashboard'
          dashboard(request)
        when '/hello'
          hello_world(request)
        when '/logout'
          logout(request)
        else
          not_found
        end
      rescue => e
        error_response(e)
      end

      private

      def dashboard(request)
        # Initialize analyzer with sample data (you may want to make this configurable)
        sdb_log_path = ENV.fetch('SDB_LOG_PATH', './spec/data/sdb.log')

        analyzer = Sdb::Analyzer::Core.new(sdb_log_path)
        request_analytics = calculate_request_analytics(analyzer)
        requests = prepare_requests_data(analyzer)

        # Simple dashboard with some basic info
        html = erb(:dashboard, {
                     title: 'SDB Analyzer Dashboard',
                     request_path: request.path_info,
                     timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
                     request_analytics: request_analytics || [],
                     requests: requests || []
                   })
        [200, {'Content-Type' => 'text/html'}, [html]]
      end

      def hello_world(request)
        html = erb(:hello, {
                     title: 'Hello World',
                     message: 'Hello from SDB Analyzer!',
                     timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
                     request_path: request.path_info
                   })
        [200, {'Content-Type' => 'text/html'}, [html]]
      end

      def logout(request)
        # Simple logout by returning 401 to clear basic auth
        [401, {
           'Content-Type' => 'text/html',
           'WWW-Authenticate' => 'Basic realm="SDB Analyzer"'
         }, ['<html><body><h1>Logged out</h1><p><a href="/">Login again</a></p></body></html>']]
      end

      def not_found
        [404, {'Content-Type' => 'text/html'}, ['<html><body><h1>404 - Not Found</h1></body></html>']]
      end

      def error_response(error)
        [500, {'Content-Type' => 'text/html'}, ["<html><body><h1>Error</h1><p>#{error.message}</p></body></html>"]]
      end

      def erb(template, locals = {})
        template_path = File.join(File.dirname(__FILE__), 'web', 'views', "#{template}.erb")
        layout_path = File.join(File.dirname(__FILE__), 'web', 'views', 'layout.erb')

        template_content = File.read(template_path)
        layout_content = File.read(layout_path)

        # Create a binding with the local variables
        b = binding
        locals.each { |key, value| b.local_variable_set(key, value) }

        # Render the template content first
        content = ERB.new(template_content).result(b)

        # Make content available to layout
        b.local_variable_set(:content, content)

        # Render the layout with the content
        ERB.new(layout_content.gsub('<%= yield %>', '<%= content %>')).result(b)
      end

      # Rack middleware to add basic authentication
      class BasicAuth
        def initialize(app, username, password)
          @app = app
          @username = username
          @password = password
        end

        def call(env)
          auth = Rack::Auth::Basic::Request.new(env)

          if auth.provided? && auth.basic? && auth.credentials
            provided_username, provided_password = auth.credentials

            # Use secure comparison to prevent timing attacks (like Sidekiq does)
            username_matches = secure_compare(
              ::Digest::SHA256.hexdigest(provided_username),
              ::Digest::SHA256.hexdigest(@username)
            )
            password_matches = secure_compare(
              ::Digest::SHA256.hexdigest(provided_password),
              ::Digest::SHA256.hexdigest(@password)
            )

            if username_matches && password_matches
              return @app.call(env)
            end
          end

          unauthorized
        end

        private

        # Secure comparison to prevent timing attacks (similar to ActiveSupport::SecurityUtils.secure_compare)
        def secure_compare(a, b)
          return false unless a.bytesize == b.bytesize

          l = a.unpack "C#{a.bytesize}"
          res = 0
          b.each_byte { |byte| res |= byte ^ l.shift }
          res == 0
        end

        def unauthorized
          [401, {
             'Content-Type' => 'text/html',
             'WWW-Authenticate' => 'Basic realm="SDB Analyzer"'
           }, ['<html><body><h1>401 - Unauthorized</h1><p>Please provide valid credentials.</p></body></html>']]
        end
      end

      # Helper method to create authenticated web app (similar to Sidekiq's pattern)
      def self.with_auth(username = nil, password = nil)
        username ||= ENV.fetch('SDB_WEB_USERNAME', 'admin')
        password ||= ENV.fetch('SDB_WEB_PASSWORD', 'secret')

        Rack::Builder.new do
          use Rack::Session::Cookie,
              secret: ENV.fetch('SDB_WEB_SESSION_SECRET', 'change_me_in_production'),
              same_site: true,
              max_age: 86400
          use BasicAuth, username, password
          run Web
        end
      end

      def calculate_request_analytics(analyzer)
        return [] unless analyzer&.request_table&.requests

        # Group requests by path
        grouped_requests = analyzer.request_table.requests.group_by(&:path)

        analytics = grouped_requests.map do |path, requests|
          # Calculate latencies in milliseconds
          latencies = requests.map do |req|
            if req.start_ts && req.end_ts
              # Convert from nanoseconds to milliseconds
              (req.end_ts - req.start_ts) / 1_000.0
            else
              req.cpu_time_ms || 0
            end
          end.compact.sort

          next if latencies.empty?

          # Calculate statistics
          avg_latency = latencies.sum / latencies.size.to_f
          p50 = percentile(latencies, 50)
          p90 = percentile(latencies, 90)
          p99 = percentile(latencies, 99)

          # Get controller and action from first request (assuming they're the same for same path)
          sample_request = requests.first

          {
            path: path,
            controller: sample_request.controller,
            action: sample_request.action,
            request_count: requests.size,
            avg_latency: avg_latency.round(2),
            p50_latency: p50.round(2),
            p90_latency: p90.round(2),
            p99_latency: p99.round(2)
          }
        end.compact.sort_by { |item| -item[:request_count] } # Sort by request count descending

        analytics
      end

            def percentile(sorted_array, percentile)
        return 0 if sorted_array.empty?

        index = (percentile / 100.0) * (sorted_array.length - 1)
        lower = sorted_array[index.floor]
        upper = sorted_array[index.ceil]

        lower + (upper - lower) * (index - index.floor)
      end

      def prepare_requests_data(analyzer)
        return [] unless analyzer&.request_table&.requests

        requests_data = analyzer.request_table.requests.map do |req|
          # Calculate latency
          latency = if req.start_ts && req.end_ts
            (req.end_ts - req.start_ts) / 1_000.0  # Convert to milliseconds
          else
            req.cpu_time_ms || 0
          end

          # Format timestamps
          start_time = req.start_ts ? Time.at(req.start_ts / 1_000_000_000.0).strftime('%H:%M:%S.%3N') : '-'
          end_time = req.end_ts ? Time.at(req.end_ts / 1_000_000_000.0).strftime('%H:%M:%S.%3N') : '-'

          {
            trace_id: req.trace_id,
            path: req.path,
            controller: req.controller,
            action: req.action,
            status: req.status,
            latency: latency.round(2),
            start_time: start_time,
            end_time: end_time,
            thread_id: req.thread_id,
            process_id: req.process_id
          }
        end

        # Sort by start timestamp (most recent first)
        requests_data.sort_by { |req| -(req[:trace_id] || '').hash }
      end
    end
  end
end
