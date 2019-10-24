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

        register_facet ForemanPasswordstate::PasswordstateHostFacet, :passwordstate_facet do
          configure_host do
            # extend_model ForemanPasswordstate::HostManagedExtensions # The #root_pass override fails if done here
            add_tabs passwordstate_facet: 'foreman_passwordstate/passwordstate_facets/passwordstate_facet'
          end
          configure_hostgroup ForemanPasswordstate::PasswordstateHostgroupFacet
        end

        parameter_filter Host::Managed, passwordstate_facet_attributes: %i[passwordstate_server_id password_list_id]
        parameter_filter Hostgroup, passwordstate_facet_attributes: %i[passwordstate_server_id password_list_id]
      end
    end

    # Precompile any JS or CSS files under app/assets/
    # If requiring files from each other, list them explicitly here to avoid precompiling the same
    # content twice.
    assets_to_precompile =
      Dir.chdir(root) do
        Dir['app/assets/javascripts/**/*', 'app/assets/stylesheets/**/*'].map do |f|
          f.split(File::SEPARATOR, 4).last.gsub(/\.scss\Z/, '')
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
        Host::Managed.send(:prepend, ForemanPasswordstate::HostManagedExtensions)
        Hostgroup.send(:prepend, ForemanPasswordstate::HostgroupExtensions)
        HostsController.send(:prepend, ForemanPasswordstate::HostsControllerExtensions)
        HostgroupsController.send(:prepend, ForemanPasswordstate::HostgroupsControllerExtensions)
        Operatingsystem.send(:prepend, ForemanPasswordstate::OperatingsystemExtensions)
      rescue StandardError => e
        Rails.logger.fatal "foreman_passwordstate: skipping engine hook (#{e})"
      end
    end
  end
end
