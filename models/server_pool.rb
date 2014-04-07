class ServerPool < Ohm::Model
  attribute :name
  attribute :host
  attribute :port
  attribute :category
  index :category
  index :name
  index :data_count
  counter :data_count
  unique :name
  collection :data_indexes, :DataIndex


  def self.count
    all.to_a.size
  end

  #add a indexes: {action: 'add_indexes', user_id: 1 category: 'matching', indexes:[1,100,500]}
  def self.add_indexes!(data)
    data_output = {}
    available_servers = find_available_servers(data[:category])
    data[:indexes].each do |index_id|
      next_server(available_servers) do |server|
        server.store_index({category: data[:category], user_id: data[:user_id], trainer_id: index_id})
        data_output[server] ||= {action: 'add_indexes', indexes: [], user_id: data[:user_id]}
        data_output[server][:indexes].push index_id
      end
    end
    data_output
  end

  #update a index: {action: 'update_index', index_id: 100}}
  def self.update_index!(data)
    data_index = DataIndex.find(trainer_id: data[:indexes].first).first
    {data_index.server_pool => data}
  end


  def self.find_available_servers(category)
    find(category: category).
      except(data_count: Settings.limits.send(category)).
      sort{|a,b| a.data_count<=>b.data_count}
  end

  def full?
    Settings.limits.send(category).to_i == data_count
  end

  def url
    "http://#{host}:#{port}/"
  end

  def store_index( data)
    DataIndex.create(data.merge(server_pool: self))
    self.incr(:data_count)
  end

  private

  def self.next_server(servers)
    server = servers.shift
    yield server
    servers.push server unless server.full?
  end


end