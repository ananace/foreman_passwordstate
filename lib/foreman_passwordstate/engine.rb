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

    initializer 'foreman_passwordstate.register_plugin', before: :finisher_hook do |_app|
      Foreman::Plugin.register :foreman_passwordstate do
        requires_foreman '>= 1.16'

        # add menu entry
        menu :top_menu, :passwordstate_servers,
             url_hash: { controller: :passwordstate_servers, action: :index },
             caption: N_('Passwordstate Servers'),
             parent: :infrastructure_menu

        register_facet ForemanPasswordstate::PasswordstateFacet, :passwordstate_facet
        parameter_filter Host::Managed, passwordstate_facet_attributes: %i[passwordstate_server_id]
      end
    end

    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last
        end
      end

    initializer 'foreman_passwordstate.assets.precompile' do |app|
      app.config.assets.precompile += assets_to_precompile
    end

    initializer 'foreman_passwordstate.configure_assets', group: :assets do
      SETTINGS[:foreman_passwordstate] = { assets: { precompile: assets_to_precompile } }
    end

    config.to_prepare do
      begin
        # Host::Managed.send(:prepend, ForemanPasswordstate::HostExtensions)
        # HostsController.send(:prepend, ForemanPasswordstate::HostsControllerExtensions)
      rescue StandardError => e
        Rails.logger.fatal "foreman_passwordstate: skipping engine hook (#{e})"
      end
    end
  end
end
