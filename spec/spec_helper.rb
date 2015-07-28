require 'nagios_nrdp'
require 'webmock/rspec'
require 'coveralls'

if ENV['COVERAGE']
  Coveralls.wear!
end
