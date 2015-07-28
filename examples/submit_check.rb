#!/usr/bin/env ruby
require 'nagios_nrdp'

def get_user_input(prompt)
  print "#{prompt}: "
  gets.chomp
end

url = get_user_input('NRDP URL')
token = get_user_input('Token')
hostname = get_user_input('Hostname')
state = get_user_input('State')
output = get_user_input('Output')

puts

nrdp = Nagios::Nrdp.new(url: url, token: token)
if nrdp.submit_check(hostname: hostname, state: state.to_i, output: output)
  puts 'Check submitted successfully.'
  exit 0
else
  puts 'Failed to submit check!'
  exit 1
end
