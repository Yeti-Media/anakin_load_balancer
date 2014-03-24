module Anakin
  class Servers

    attr_accessor :servers

    def initialize
      self.servers = ServerPool.all.to_a
    end

    def add_server(server)
      self.servers << server
    end

    def remove_server(server)
      self.servers.delete(server)
    end

    def send_data(data, resp)
      if data
        multi = EventMachine::MultiRequest.new
        data.each do |server, d|
          multi.add(server.name, EventMachine::HttpRequest.new(server.url).post(body: Yajl::Encoder.encode(d)))
        end
        multi.callback  do
          resp.status = 200
          resp.content_type 'application/json'
          content = []
          multi.responses[:callback].each do |server, conn|
            content << conn.response
          end
          resp.content = "[#{content.join(',')}]"
          resp.send_response 
        end
      else
        resp.content = "OK"
        resp.status = 200
        resp.content_type 'application/json'
        resp.send_response  
      end
    end

  end
end
