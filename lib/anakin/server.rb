module Anakin
  class Servers
    attr_accessor :servers

    def initialize(conn)
      self.servers = Anakin::ServerPool.all.to_a
      servers.each do |s|  
        conn.server s['name'], host: s['host'], port: s['port']
      end
    end

  end
end
