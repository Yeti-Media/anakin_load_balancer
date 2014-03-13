module Anakin
  class Request

    
    attr_accessor :servers, :raw_data, :data , :conn

    def initialize(servers, data)
      self.servers = servers
      self.raw_data = data
      self.conn = conn
    end

    #process image: {action: 'matching' user_id: 1, category: 'matching', scenario: <SCENARIO IMAGE DATA OR DATA EXTRACTED> }
    #add indexes: {action: 'add_indexes', user_id: 1, indexes:[1,2,100,..]}
    #update a index: {action: 'update_index', index:{id: 100}}
    #add a server: {action: 'add_server', server: {name: 'anakin1', host: '192.168.1.1', port: 5679, category: 'comparison'}}
    #remove a server: {action: 'remove_server', server: {name: 'anakin1'}}
    def process!
      parse
      process
    end

    private

    def parse
      parser = Http::Parser.new
      json_parser = Yajl::Parser.new(:symbolize_keys => true)
      self.data = json_parser.parse(raw_data)
    end

    def process
      actions = %w(add_server add_indexes add_index 
                   update_index matching comparison ocr face_detection 
                   face_recognition remove_server)
      if actions.include? data[:action]
        return send(data[:action])
      else
        return nil
      end
    end    

    #add a server: {action: 'add_server', server: {name: 'anakin1', host: '192.168.1.1', port: 5679, category: 'comparison'}}
    def add_server
      s = ServerPool.create(data[:server])
      servers.add_server(s)
      nil
    end

    #remove a server: {action: 'remove_server', server: {name: 'anakin1'}}
    def remove_server
      server = ServerPool.find(data[:server]).first
      server.data_indexes.to_a.map &:delete      
      server.delete
      servers.remove_server(server)
      nil
    end

    #add a indexes: {action: 'add_indexes', user_id: 1 indexes:[{id:1, category: 'matching'},..]}
    def add_indexes
      ServerPool.add_indexes!(data)
    end

    #update a index: {action: 'update_index', index:{id: 100}}
    def update_index
      ServerPool.update_index!(data)
    end

    #process image: {action: 'matching' user_id: 1, category: 'matching', scenario_id: 1234 }
    def matching
      data_output = {}
      data_indexes = DataIndex.find(user_id: data[:user_id], category: data[:category]).to_a
      data_indexes.each do |data_index|
        data_output[data_index.server_pool] ||= {indexes: [], action: 'process_image' , scenario_id: data[:scenario_id]}
        data_output[data_index.server_pool][:indexes].push(data_index.trainer_id)
      end
      data_output
    end

    def comparison
      data_output = {}
      ServerPool.find(category: 'comparison').each do |server|
        data_output[server] = {action: 'comparison', user_id: data[:user_id], scenario_id: data[:scenario_id]}
      end
    end

    def ocr
      data_output = {}
      servers = ServerPool.find(category: 'ocr').to_a
      server = servers[rand(servers.length -1)]
      data_output[server] = {action: 'ocr', scenario_id: data[:scenario_id]}
    end
    
  end
end