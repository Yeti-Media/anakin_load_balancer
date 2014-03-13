class Settings < Settingslogic

  source "#{File.expand_path(File.dirname(__FILE__))}/../config/application.yml"
  namespace 'envs'
end