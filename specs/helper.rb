module Helper

  extend self

  def perform_request(body)
    @conn.post do |req|
      req.url '/'
      req.headers['Content-Type'] = 'application/json'
      req.body = Yajl::Encoder.encode(body)
    end
  end

  def load_servers
    @server_thread = []
    @server_thread << Thread.new do
      Rack::Handler::Thin.run Helper::TestServer.new, :Port => 6001
    end
    @server_thread << Thread.new do
      Rack::Handler::Thin.run Helper::TestServer.new, :Port => 6002
    end
    sleep(2)
  end

  def add_server(body)
    perform_request(body)
  end

  def delete_server(name)
    body = {action: 'remove_server', server: {name: name}}
    perform_request(body)
  end

  class TestServer
    def call(env)
      [200, {"Content-Type" => "application/json"}, "{\"status\": \"success\"}"]
    end
  end

end