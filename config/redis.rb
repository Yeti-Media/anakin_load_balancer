#Ohm.redis = Redic.new("redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}/#{ENV['REDIS_DB']}")
Ohm.redis = Redic.new("redis://localhost:6379/")
