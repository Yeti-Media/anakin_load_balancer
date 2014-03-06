require 'bundler'

Bundler.require

Dir['./config/**/*.rb'].each do |file|
  require file unless file.include?('deploy.rb')
end

Dir['./models/**/*.rb'].each do |file|
  require file
end

Dir['./lib/**/*.rb'].each do |file|
  require file
end


