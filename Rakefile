require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'

task :default => :test

RSpec::Core::RakeTask.new(:spec)

desc "Run syntax, lint, and rspec tests..."
task :test => [
  :validate,
  :syntax,
  :lint,
  :spec,
]
