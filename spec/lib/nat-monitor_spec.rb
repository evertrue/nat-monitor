require 'spec_helper'
require 'byebug'
require 'nat-monitor'

describe EtTools::NatMonitor do
  before(:each) do
    @route_table_id = 'rtb-00000000'
    @my_instance_id = 'i-00000001'

    @other_nodes = { 'i-00000002' => '1.1.1.2',
                     'i-00000003' => '1.1.1.3' }

    @yaml_conf = { 'route_table_id' => @route_table_id,
                   'nodes' => (
                     { @my_instance_id => '1.1.1.1' }
                   ).merge(@other_nodes) }

    filepath = 'bogus_filename.yml'

    allow_any_instance_of(EtTools::NatMonitor).to receive(:load_conf)
      .with(filepath).and_return(@yaml_conf)

    @nat_monitor = EtTools::NatMonitor.new(filepath)

    @defaults = { 'pings' => 3,
                  'ping_timeout' => 1,
                  'heartbeat_interval' => 10 }

    allow(@nat_monitor).to receive(:my_instance_id).and_return(@my_instance_id)
    allow(@nat_monitor).to receive(:steal_route).and_return(true)
  end

  context 'fewer than 3 nodes are specified' do
    before do
      allow(YAML).to receive(:load_file).with(any_args)
      @nat_monitor.instance_variable_set(
        :@conf,
        ({ 'route_table_id' => @route_table_id,
           'nodes' => @other_nodes })
      )
      allow(@nat_monitor).to receive(:route_exists?).with(any_args)
        .and_return true
    end

    it 'exits with status 3' do
      expect(@nat_monitor).to receive(:exit).with(3)
      @nat_monitor.validate!
    end
  end

  context 'invalid route is specified' do
    # connection.route_tables.map(&:id).include? route_id
    before do
      allow_any_instance_of(Fog::Compute::AWS).to receive(:route_tables)
        .and_return [
          double('route_tables',
                 id: 'rtb-99999999')
        ]
    end

    it 'exits with status 2' do
      expect(@nat_monitor).to receive(:route_exists?).with(@route_table_id)
        .and_return false
      expect(@nat_monitor).to receive(:exit).with(2)
      @nat_monitor.validate!
    end
  end

  context 'no route is specified' do
    before do
      @nat_monitor.instance_variable_set(
        :@conf,
        'nodes' => ({ @my_instance_id => '1.1.1.1' }).merge(@other_nodes)
      )
    end

    it 'exits with status 1' do
      expect(@nat_monitor).to receive(:exit).with(1)
      @nat_monitor.validate!
    end
  end

  context 'local node is the master' do
    before do
      allow(@nat_monitor).to(
        receive(:current_master).and_return(@my_instance_id)
      )
    end

    it 'sets @conf correctly' do
      expect(@nat_monitor.instance_variable_get(:@conf)).to eq(
        @yaml_conf.merge(@defaults)
      )
    end

    it 'and knows that it is master' do
      expect(@nat_monitor).to receive(:am_i_master?).and_return(true)
      @nat_monitor.heartbeat
    end

    it 'and does not check for unreachable nodes' do
      expect(@nat_monitor).to_not receive(:unreachable_nodes)
      @nat_monitor.heartbeat
    end
  end

  context 'local node is not master' do
    before do
      allow(@nat_monitor).to(
        receive(:current_master).and_return('i-00000002')
      )
    end

    context 'and can ping everything' do
      before do
        allow(@nat_monitor).to receive(:pingable?).with(any_args)
          .and_return true
      end

      it 'does not try to steal the route' do
        expect(@nat_monitor).to_not receive(:steal_route)
        @nat_monitor.heartbeat
      end
    end

    context 'and can\'t ping anything' do
      before do
        allow(@nat_monitor).to receive(:pingable?).with(any_args)
          .and_return false
      end

      it 'counts unreachable nodes correctly' do
        allow(@nat_monitor).to receive(:other_nodes)
          .and_return(@other_nodes)
        expect(@nat_monitor).to receive(:unreachable_nodes)
          .and_return(@other_nodes)
        @nat_monitor.heartbeat
      end

      it 'does not try to steal the route' do
        expect(@nat_monitor).to receive(:unreachable_nodes)
          .and_return(@other_nodes)
        expect(@nat_monitor).to_not receive(:steal_route)
        @nat_monitor.heartbeat
      end
    end

    context 'and can\'t ping the master' do
      before do
        allow(@nat_monitor).to receive(:pingable?).with('1.1.1.2')
          .and_return false
        allow(@nat_monitor).to receive(:pingable?).with('1.1.1.3')
          .and_return true
        allow_any_instance_of(Fog::Compute::AWS).to receive(:replace_route)
          .with(@route_table_id, '0.0.0.0', @my_instance_id)
          .and_return true
      end

      it 'computes the list of other nodes correctly' do
        expect(@nat_monitor).to receive(:other_nodes)
          .exactly(2).times.and_return(@other_nodes)
        @nat_monitor.heartbeat
      end

      it 'finds i-00000002 unreachable' do
        expect(@nat_monitor).to receive(:unreachable_nodes)
          .and_return('i-00000002' => '1.1.1.2')
        @nat_monitor.heartbeat
      end

      it 'tries to steal the route' do
        allow(@nat_monitor).to receive(:other_nodes)
          .and_return(@other_nodes)
        expect(@nat_monitor).to receive(:steal_route)
        @nat_monitor.heartbeat
      end
    end

    context 'mocking and can\'t ping the master' do
      before do
        @nat_monitor.instance_variable_set(
          :@conf,
          @yaml_conf.merge('mocking' => true).merge(@defaults)
        )
      end

      it 'does not steal the route when mocking is enabled' do
        expect(@nat_monitor.connection).to_not receive(:replace_route)
        @nat_monitor.heartbeat
      end
    end
  end
end
