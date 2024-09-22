# frozen_string_literal: true

require_relative "lib/sdb/analyzer/version"

Gem::Specification.new do |spec|
  spec.name = "sdb-analyzer"
  spec.version = Sdb::Analyzer::VERSION
  spec.authors = ["Mike Yang"]
  spec.email = ["yfractal@gmail.com"]

  spec.summary = "Stack Debugger Analyzer"
  spec.description = "Stack Debugger Analyzer."
  spec.required_ruby_version = ">= 3.0.0"


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'ruby-graphviz'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'pry'
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
