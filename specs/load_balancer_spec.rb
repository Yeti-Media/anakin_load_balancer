require_relative './spec_helper'


describe "Load Balancer" do
  include POSIX::Spawn
  include Helper

  Helper.load_servers
  before do 
    @conn =  Faraday.new('http://127.0.0.1:8080/')
  end

  it "should add a new server" do
    action = {action: 'add_server', server: {name: 'anakin1', host: '127.0.0.1', port: 5679, category: 'matching'}}
    lambda do
      add_server(action)
    end.should change(ServerPool,:count).by(1)
    delete_server(action[:server][:name])
  end

  it "should remove a server" do
    server = {action: 'add_server', server: {name: 'anakin1', host: '127.0.0.1', port: 5679, category: 'matching'}}
    add_server(server)
    lambda do
      action = {action: 'remove_server', server: {name: 'anakin1'}}
      perform_request(action) rescue nil
    end.should change(ServerPool,:count).by(-1)
  end

  describe "when add indexes" do
    before do 
      body = {action: 'add_server', server: {name: 'anakin1', host: '127.0.0.1', port: 6001, category: 'matching'}}
      add_server(body)
      body = {action: 'add_server', server: {name: 'anakin2', host: '127.0.0.1', port: 6002, category: 'matching'}}
      add_server(body)
    end
    
    after do
      delete_server('anakin1')
      delete_server('anakin2')
    end

    it "should add a new data" do
      @body = {action: 'add_indexes', user_id: 1, category: 'matching', indexes:[1,2]}
      lambda do
        perform_request(@body)
      end.should change(DataIndex,:count).by(2)
    end

    it "should send the data to the backend servers" do
      @body = {action: 'add_indexes', user_id: 1, category: 'matching', indexes:[1,2]}
      response = perform_request(@body)
      Yajl::Parser.parse(response.body).count.should be(2)
    end
  end

  describe "when update index" do
    before do
      body = {action: 'add_server', server: {name: 'anakin1', host: '127.0.0.1', port: 6001, category: 'matching'}}
      add_server(body)
      body = {action: 'add_server', server: {name: 'anakin2', host: '127.0.0.1', port: 6002, category: 'matching'}}
      add_server(body)
    end

    after do
      delete_server('anakin1')
      delete_server('anakin2')
    end

    it "should update the index on server 1 and 2" do
      add_index = {action: 'add_indexes', user_id: 1, category: 'matching', indexes:[100,200]}
      perform_request(add_index)
      @body = {action: 'update_index', index_id: 100}
      response = perform_request(@body)
      Yajl::Parser.parse(response.body).should == [{"status" => "success"}]
    end

  end

  describe "when process image" do
    before do
      body = {action: 'add_server', server: {name: 'anakin1', host: '127.0.0.1', port: 6001, category: 'matching'}}
      add_server(body)
      body = {action: 'add_server', server: {name: 'anakin2', host: '127.0.0.1', port: 6002, category: 'matching'}}
      add_server(body)
    end

    after do
      delete_server('anakin1')
      delete_server('anakin2')
    end

    it "should receive two responses" do
      add_indexes = {action: 'add_indexes', user_id: 1, category: 'matching', indexes:[1,2]}
      perform_request(add_indexes)
      @body =  {action: 'matching', user_id: 1, category: 'matching', scenario_id: 1234 }
      response = perform_request(@body)
      Yajl::Parser.parse(response.body).count.should == 2
    end

  end
end