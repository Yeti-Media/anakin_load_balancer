module Anakin
  class ServerPool < Ohm::Model
    attribute :name
    attribute :host
    attribute :port
    attribute :category
    index :category
    counter :data_count
    collection :datas, 'Anakin::DataIndex'

    #add a indexes: {action: 'add_indexes', user_id: 1 category: 'matching', indexes:[1,100,500]}
    def self.add_indexes!(data)
      data_output = {}
      available_servers = find_available_servers(data[:category])
      data[:indexes].each do |index_id|
        next_server(available_servers) do |server|
          store_index(server, {category: data[:category], user_id: data[:user_id], index_id: index_id})
          data_output[server.name.to_sym] ||= {action: 'add_indexes', indexes: [], user_id: data[:user_id]}
          data_output[server.name.to_sym][:indexes].push index_id
        end
      end
      data_output
    end

    #add a index: {action: 'add_index', index_id: 100, category: 'matching', user_id: 1}
    def self.add_index!(data)
      data_output = {}
      available_servers = find_available_servers(data[:category])
      next_server(available_servers) do |server|
        store_index(server, {category: data[:category], user_id: data[:user_id], index_id: index_id})
        data_output[server.name.to_sym] = data
      end
      data_output
    end

    #update a index: {action: 'update_index', index_id: 100}}
    def self.update_index!(data)
      data_index = Anakin::DataIndex.find(index_id: data[:index_id])
      {data_index.server.name.to_sym => data}
    end


    def self.find_available_servers(category)
      find(category: category).except(data_count: Settings.limits.send(category)).sort{|a,b| a.data_count<=>b.data_count}
    end

    private

    def self.next_server(servers)
      server = servers.shift
      yield server
      servers.push server unless server.full?
    end

    def self.store_index(server, data)
      data = server.datas.create(data)
      server.incr(:data_count)
    end

    




    def full?
      Settings.limits.send(category).to_i == data_count
    end



  end
end
