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
          multi.add(server.name, EventMachine::HttpRequest.new(server.url).
                                      post(body: Yajl::Encoder.encode(d), header:{'connection' => 'close'},
                                           timeout: 120))
        end
        multi.callback  do
          resp.status = 200
          resp.content_type 'application/json'
          content = []
          multi.responses[:callback].each do |server, conn|
            begin 
              body = conn.response.match(/\{(.*)\}|\[(.*)\]/)
              single_response = Yajl::Parser.parse(body[0])
              if single_response.is_a?(Hash) || single_response.is_a?(Array)
                content << body[0]
              end
            rescue Yajl::ParseError => e
              content << e.message
              Rollbar.report_exception(e, {server: server, data: data})
            rescue NoMethodError => e
              Rollbar.report_exception(e, {server: server, data: data})
              content << ""
            end
          end
          resp.content = "[#{content.join(',')}]"
          puts "RESPONSES"
          puts resp.content
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
