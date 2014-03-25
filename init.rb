require 'bundler'

Bundler.require

Dir['./config/**/*.rb'].each do |file|
  require file unless file.include?('deploy')
end

Dir['./models/**/*.rb'].each do |file|
  require file
end

Dir['./lib/**/*.rb'].each do |file|
  require file
end


