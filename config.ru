#!/usr/bin/env ruby

require 'bundler/setup'
require_relative 'lib/sdb/analyzer'
require_relative 'lib/sdb/analyzer/web'

# Set default credentials if not provided via environment variables
ENV['SDB_WEB_USERNAME'] ||= 'admin'
ENV['SDB_WEB_PASSWORD'] ||= 'secret'
ENV['SDB_WEB_SESSION_SECRET'] ||= 'change_me_in_production_please'

puts "Starting SDB Analyzer Web Interface..."
puts "Default credentials: admin / secret"
puts "Set SDB_WEB_USERNAME and SDB_WEB_PASSWORD environment variables to change"
puts ""

# Run the authenticated web application
run Sdb::Analyzer::Web.with_auth
