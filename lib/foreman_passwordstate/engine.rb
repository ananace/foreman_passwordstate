# frozen_string_literal: true

require 'deface'

module ForemanPasswordstate
  class Engine < ::Rails::Engine
    engine_name 'foreman_passwordstate'

    config.autoload_paths += Dir["#{config.root}/app/lib"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/services"]

    initializer 'foreman_passwordstate.load_app_instance_data' do |app|
      ForemanPasswordstate::Engine.paths['db/migrate'].existent.each do |path|
        app.config.paths['db/migrate'] << path
      end
    end

    initializer 'foreman_passwordstate.register_plugin', before: :finisher_hook do |app|
      app.reloader.to_prepare do
        require_relative 'register'
      end
    end

    config.to_prepare do
      Host::Managed.prepend ForemanPasswordstate::HostManagedExtensions
      HostsController.prepend ForemanPasswordstate::HostsControllerExtensions
      HostgroupsController.prepend ForemanPasswordstate::HostgroupsControllerExtensions
      Operatingsystem.prepend ForemanPasswordstate::OperatingsystemExtensions
    rescue StandardError => e
      Rails.logger.fatal "foreman_passwordstate: skipping engine hook (#{e})"
    end
  end
end
