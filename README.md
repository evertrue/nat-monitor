[![Gem Version](https://badge.fury.io/rb/nat-monitor.svg)](http://badge.fury.io/rb/nat-monitor)

# nat-monitor

Monitors a quorum of NAT servers for an outage and reassigns the specified EC2 route table to point to a working server.

## Requirements

The basic AWS setup required to make this work is actually pretty complex. I recommend reading my [how-to blog post](http://evertrue.github.io/blog/2015/07/06/the-right-way-to-set-up-nat-in-ec2/). Feedback is highly appreciated.

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

Optional properties include (Values shown are the defaults):

```yaml
pings: 3
ping_timeout: 1
heartbeat_interval: 10
monitor_enabled: false
```

Optional AWS configuration include:

```yaml
aws_access_key_id: YOUR ACCESS KEY
aws_secret_access_key: YOUR SECRET KEY
region: us-east-1
```

Note that:

- If you don't specify the AWS credentials it will use the IAM role of the instance

The NAT Monitor has the ability to report out to [Cronitor.io](http://cronitor.io) its status. This comes courtesy of the [`cronitor`](https://github.com/evertrue/cronitor) gem.

You will need to set `monitor_enabled: true` and then supply either a Cronitor API token & monitor options:

```yaml
monitor_enabled: true
monitor_token: abcd
monitor_opts:
  name: My Fancy Monitor
  notifications:
    emails:
      - test@example.com
    slack:
      - https://url-to-slack.webhook
    pagerduty:
      - pagerduty-service-api-token
    phones:
      - +12345678900
    webhooks:
      - 'http://example.com'
  rules:
    - rule_type: 'not_run_in',
      duration: 5,
      time_unit: 'seconds'
```

or the code for an existing Cronitor monitor:

```yaml
monitor_enabled: true
monitor_code: abcd
```

## Contributing

1. Fork it ( https://github.com/evertrue/nat-monitor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
