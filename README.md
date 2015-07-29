# Nagios::Nrdp

[![Build Status](https://travis-ci.org/stjeanp/nagios_nrdp.svg?branch=master)](https://travis-ci.org/stjeanp/nagios_nrdp) [![Coverage Status](https://coveralls.io/repos/stjeanp/nagios_nrdp/badge.svg?branch=master&service=github)](https://coveralls.io/github/stjeanp/nagios_nrdp?branch=master)

## About

The Nagios::Nrdp module provides the ability to submit passive check results and commands to a Nagios server using [NRDP](https://exchange.nagios.org/directory/Addons/Passive-Checks/NRDP--2D-Nagios-Remote-Data-Processor/details). It currenly only supports token based authentication.

## Installation Instructions

1. Install and configure [NRDP](https://exchange.nagios.org/directory/Addons/Passive-Checks/NRDP--2D-Nagios-Remote-Data-Processor/details).
2. `gem install nagios_nrdp`

## Basic Usage

* Send a host passive check

```ruby
require 'nagios_nrdp'

url = 'http://some.host/nrdp'
token = 'your token'
hostname = 'hostname'
state = 1
output = 'DOWN'

nrdp = Nagios::Nrdp.new(url: url, token: token)
nrdp.submit_check(hostname: hostname, state: state.to_i, output: output)
```

* Send a service passive check:

```ruby
require 'nagios_nrdp'

url = 'http://some.host/nrdp'
token = 'your token'
hostname = 'hostname'
servicename = 'service'
state = 1
output = 'DOWN'

nrdp = Nagios::Nrdp.new(url: url, token: token)
nrdp.submit_check(hostname: hostname, servicename: servicename, state: state.to_i, output: output)
```

* Send multiple passive checks:

```ruby
require 'nagios_nrdp'

url = 'http://some.host/nrdp'
token = 'your token'
checks = [{ hostname: 'host1', state: 1, output: 'DOWN' },
          { hostname: 'host2', state: 0, output: 'UP' }]

nrdp = Nagios::Nrdp.new(url: url, token: token)
nrdp.submit_checks(checks)
```


* Send a command:

```ruby
require 'nagios_nrdp'

url = 'http://some.host/nrdp'
token = 'your token'
command = 'COMMAND;hostname'

nrdp = Nagios::Nrdp.new(url: url, token: token)
nrdp.submit_command(command)
```

## Contributing

1. Fork it ( https://github.com/stjeanp/nagios_nrdp/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
