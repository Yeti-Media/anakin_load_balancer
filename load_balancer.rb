#!/usr/bin/env ruby
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
      begin
        @request = Anakin::Request.new(servers, @http_post_content)
        puts "SERVERS"
        puts self.servers.inspect
        puts "REQUEST"
        puts @request.inspect
        @data = @request.process!
        puts "DATA"
        puts @data.inspect
      rescue Exception => e
        Rollbar.report_exception(e, {data: @http_post_content})
        resp.status = 500
        resp.content = '{"error":"Internal Server Error"}'
        resp.send_response
      end 
    end

  # Callback block to execute once the request is fulfilled
    callback = proc do
      begin 
        if @request.valid?
          servers.send_data(@data, resp)
        else
          resp.status = 422
          resp.content = "{\"error\":\"#{@request.error}\"}"
          puts "RESPONSES"
          puts resp.content
          resp.send_response
        end
      rescue Exception => e
        Rollbar.report_exception(e, {data: @data})
        resp.status = 500
        resp.content = '{"error":"Internal Server Error"}'
        resp.send_response
      end
    end

    # Let the thread pool (20 Ruby threads) handle request
      EM.defer(operation, callback)
  end
end

#Daemons.daemonize

#pid_file = PidFile.new(:piddir => '/var/lock', :pidfile => "anakin_load_balancer.pid")

Dante.run('blog', {log_path: './log/anakin_load_balancer.log'}) do |opts|
  opts[:port] ||= 8080
  EventMachine::run {
    EventMachine::start_server("0.0.0.0", opts[:port], LoadBalancer)
    puts "Listening... on port #{opts[:port]}"
  }

end