class Settings < Settingslogic
  source "../config/application.yml"
  namespace 'envs'
end