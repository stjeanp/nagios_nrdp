require 'rubygems'
require 'rake'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'rubocop/rake_task'

task :default => :test

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/**/*.rb']
  task.formatters = ['files']
  task.fail_on_error = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'nagios_nrdp'
    gem.summary = 'A ruby gem for submitting passive checks and commands to Nagios through NRDP.'
    gem.description = 'A pure ruby implementation an NRDP client for submitting passive checks and commands to Nagios through NRDP.'
    gem.email = 'stjeanp@pat-st-jean.com'
    gem.homepage = 'http://github.com/stjeanp/nrdp'
    gem.authors = ['stjeanp']
    gem.require_path = 'lib'
    gem.files        = %w(README.md Rakefile) + Dir['lib/**/*'] + Dir['spec/**/*']
    gem.test_files   = Dir['spec/**/*']
    gem.licenses     = ['MIT']
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end

desc "Run syntax, lint, and rspec tests..."
task :test => [
  :rubocop,
  :spec,
]
