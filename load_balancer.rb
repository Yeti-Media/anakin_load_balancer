require './init'

class LoadBalancer  < EventMachine::Connection
  include EventMachine::HttpServer

  attr_accessor :servers, :data

  def post_init
    super
    self.servers = Anakin::Servers.new()
  end

  def process_http_request
    resp = EventMachine::DelegatedHttpResponse.new( self )
    operation = proc do
      request = Anakin::Request.new(servers, @http_post_content)
      @data = request.process!
      puts "DATA"
      puts @data.inspect
    end

    # Callback block to execute once the request is fulfilled
    callback = proc do 
      servers.send_data(@data, resp)
    end

    # Let the thread pool (20 Ruby threads) handle request
    EM.defer(operation, callback)
  end
end


EventMachine::run {
  EventMachine::start_server("0.0.0.0", 8080, LoadBalancer)
  puts "Listening... on port 8080"
}