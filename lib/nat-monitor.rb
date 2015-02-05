module EtTools
  class NatMonitor
    require 'net/http'
    require 'net/ping'
    require 'fog'
    require 'yaml'

    def initialize(conf_file = nil)
      @conf = YAML.load_file(conf_file || '/etc/nat_monitor.yml')
      @conf = defaults.merge @conf
    end

    def run
      validate!
      output 'Starting NAT Monitor'
      main_loop
    end

    def validate!
      case
      when !@conf['route_table_id']
        output 'route_table_id not specified'
        exit 1
      when !route_exists?(@conf['route_table_id'])
        output "Route #{@conf['route_table_id']} not found"
        exit 2
      when @conf['nodes'].count < 3
        output '3 or more nodes are required to create a quorum'
        exit 3
      end
    end

    def output(message)
      puts message
    end

    def defaults
      { 'pings' => 3,
        'ping_timeout' => 1,
        'heartbeat_interval' => 10 }
    end

    def main_loop
      loop do
        heartbeat
        sleep @conf['heartbeat_interval']
      end
    end

    def heartbeat
      return if am_i_master?
      un = unreachable_nodes
      return if (un.count == other_nodes.keys.count) || # Next if I'm unreachable...
                !un.include?(current_master) # ...unless master is unreachable
      steal_route
    end

    def steal_route
      output 'Stealing route 0.0.0.0/0 on route table ' \
             "#{@conf['route_table_id']}"
      connection.replace_route(
        @conf['route_table_id'],
        '0.0.0.0/0',
        my_instance_id
      )
    end

    def unreachable_nodes
      other_nodes.select { |_node, ip| !pingable?(ip) }
    end

    def other_nodes
      @other_nodes ||= begin
        nodes = @conf['nodes'].dup
        nodes.delete my_instance_id
        nodes
      end
    end

    def pingable?(ip)
      p = Net::Ping::External.new(ip)
      p.timeout = @conf['ping_timeout']
      p.ping?
    end

    def route_exists?(route_id)
      connection.route_tables.map(&:id).include? route_id
    end

    def connection
      @connection ||= begin
        Fog::Compute::AWS.new(aws_access_key_id: 'AWS_ACCESS_KEY_ID',
                              aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY')
      end
    end

    def current_master
      default_r = connection.route_tables.get(route_table_id).routes.find do |r|
        r['destinationCidrBlock'] == '0.0.0.0/0'
      end
      default_r['instanceId']
    end

    def my_instance_id
      @my_instance_id ||= begin
        Net::HTTP.get(
          '169.254.169.254',
          '/latest/meta-data/instance-id'
        )
      end
    end

    def am_i_master?
      master_node? my_instance_id
    end

    def master_node?(node_id)
      current_master == node_id
    end
  end
end
