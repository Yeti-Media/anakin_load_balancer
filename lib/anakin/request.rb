module Anakin
  class Request

    ACTIONS = %w(add_server add_indexes add_index update_index process_image remove_server)
    attr_accessor :servers, :raw_data, :data 

    def initialize(servers, data)
      self.servers = servers
      p data.inspect
      self.raw_data = data
    end

    #process image: {action: 'process_image' user_id: 1, category: 'matching', scenario: <SCENARIO IMAGE DATA OR DATA EXTRACTED> }
    #add a server: {action: 'add_server', server: {name: 'anakin1', host: '192.168.1.1', port: 5679, category: 'comparison'}}
    #add a indexes: {action: 'add_indexes', user_id: 1, indexes:[1,2,100,..]}
    #add a index: {action: 'add_index', index_id: 100, category: 'matching', user_id: 1}
    #update a index: {action: 'update_index', index:{id: 100}}
    #remove a server: {action: 'remove_server', server: {name: 'anakin1'}}
    def process!
      parse
      process
    end

    private

    def parse
      parser = Http::Parser.new
      body = StringIO.new
      json_parser = Yajl::Parser.new(:symbolize_keys => true)
      parser.on_body = proc do |chunk|
        body << chunk
      end
      parser.on_message_complete = proc do |env|
        self.data = json_parser.parse(body)
      end  
      parser << raw_data
    end

    def process
      if ACTIONS.include? data[:action]
        return send(data[:action])
      else
        return nil
      end
    end
    

    #add a server: {action: 'add_server', server: {name: 'anakin1', host: '192.168.1.1', port: 5679, category: 'comparison'}}
    def add_server
      Anakin::Server.create(data[:server])
      nil
    end

    #remove a server: {action: 'remove_server', server: {name: 'anakin1'}}
    def remove_server
      server = Anakin::Server.find(data[:server])
      server.datas.delete_all
      server.delete
      nil
    end

    #add a indexes: {action: 'add_indexes', user_id: 1 indexes:[{id:1, category: 'matching'},..]}
    def add_indexes
      Anakin::ServerPool.add_indexes!(data)
    end

    #add a index: {action: 'add_index', user_id: 1, index:{id: 100, category: 'matching'}}
    def add_index
      Anakin::ServerPool.add_index!(data)
    end

    #update a index: {action: 'update_index', index:{id: 100}}
    def update_index
      Anakin::ServerPool.update_index!(data)
    end

    #process image: {action: 'process_image' user_id: 1, category: 'matching', scenario: <SCENARIO IMAGE DATA OR DATA EXTRACTED> }
    def process_image(data)
      
    end

  end
end