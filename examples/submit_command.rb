#!/usr/bin/env ruby
require 'nagios_nrdp'

def get_user_input(prompt)
  print "#{prompt}: "
  gets.chomp
end

url = get_user_input('NRDP URL')
token = get_user_input('Token')
command = get_user_input('Command')

puts

nrdp = Nagios::Nrdp.new(url: url, token: token)
if nrdp.submit_command(command)
  puts 'Command submitted successfully.'
  exit 0
else
  puts 'Failed to submit command!'
  exit 1
end
