require 'rails/railtie'
module CanPlay
  class Railtie < Rails::Railtie

    config.after_initialize do |app|
      app.config.paths.add 'app/resources', eager_load: true
    end
  end
end