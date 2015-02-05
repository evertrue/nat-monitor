# nat-monitor

Monitors a quorum of NAT servers for an outage and reassigns the specified EC2 route table to point to a working server.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nat-monitor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nat-monitor

## Usage

Run it as a service after creating the configuration YAML file.

E.g.:

    $ nat-monitor [OPTIONAL CONF_FILE]

By default it will check `/etc/nat_monitor.yml` for its configuration.

## Example Configuration

```yaml
---
route_table_id: rtb-00000001
nodes:
  i-00000001: 10.0.0.1
  i-00000002: 10.0.1.1
  i-00000003: 10.0.2.1
```

Optional properties include:
```yaml
pings: 3
ping_timeout: 1
heartbeat_interval: 10
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/nat-monitor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
