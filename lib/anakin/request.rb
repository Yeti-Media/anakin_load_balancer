module Anakin
  class Request

    
    attr_accessor :servers, :raw_data, :data , :conn, :error

    def initialize(servers, data)
      self.servers = servers
      self.raw_data = data
      self.conn = conn
    end

    #process image: {action: 'matching' user_id: 1, category: 'matching', scenario: <SCENARIO IMAGE DATA OR DATA EXTRACTED> }
    #add indexes: {action: 'add_indexes', user_id: 1, indexes:[1,2,100,..]}
    #update a index: {action: 'update_indexes', index:{id: 100}}
    #add a server: {action: 'add_server', server: {name: 'anakin1', host: '192.168.1.1', port: 5679, category: 'comparison'}}
    #remove a server: {action: 'remove_server', server: {name: 'anakin1'}}
    def process!
      begin
        parse
        process
      rescue Yajl::ParseError => e
        self.error = "invalid json text"
        nil
      end
    end

    def valid?
      self.error.empty?
    end

    private

    def parse
      json_parser = Yajl::Parser.new(:symbolize_keys => true)
      self.data = json_parser.parse(raw_data)
    end

    def process
      actions = %w(add_server add_indexes add_index 
                   update_index matching comparison ocr face_detection 
                   face_recognition remove_server recover)
      if actions.include? data[:action]
        return send(data[:action])
      else
        return nil
      end
    end    

    #recover server: {action: 'recover', server:{name: 'anakin1'}}
    def recover
      server = ServerPool.find(data[:server]).first
      {server => {action: 'add_indexes', indexes: server.data_indexes.map{|d| d.trainer_id.to_i} }}
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
      data_indexes = DataIndex.find(trainer_id: data[:indexes], category: data[:category]).to_a
      data_indexes.each do |data_index|
        data_output[data_index.server_pool] ||= {indexes: [], action: 'matching' , scenario: data[:scenario]}
        data_output[data_index.server_pool][:indexes].push(data_index.trainer_id.to_i)
      end
      data_output
    end

    def comparison
      data_output = {}
      ServerPool.find(category: 'comparison').each do |server|
        data_output[server] = {action: 'comparison', user_id: data[:user_id], scenario: data[:scenario_id]}
      end
      data_output
    end

    def ocr
      servers = ServerPool.find(category: 'ocr').to_a
      server = servers[rand(servers.size - 1)]
      {server => {action: 'ocr', scenario_id: data[:scenario_id]} }
    end
    
  end
end