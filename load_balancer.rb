require './init'

Proxy.start(:host => "0.0.0.0", :port => 8080) do |conn|

  p "starting on port 8080"
  anakin_servers = Anakin::Servers.new(conn)
  servers_requested = []

  conn.on_data do |data| 
    request = Anakin::Request.new(anakin_servers, data)
    data_processed = request.process!
    servers_requested = data_processed.keys
  end

  seen = []
  conn.on_response do |backend, resp|
    seen.push backend
    seen.uniq!
    EventMachine.stop if seen.size == servers_requested.size
  end

  conn.on_finish do |name|
    # keep the connection open if we're still expecting a response
    seen.count == servers_requested.size ? :close : :keep
  end

end
