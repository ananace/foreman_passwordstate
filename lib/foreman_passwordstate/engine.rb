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

        apipie_documented_controllers ["#{ForemanPasswordstate::Engine.root}/app/controllers/api/v2/*.rb"]

        security_block :foreman_passwordstate do
          permission :view_passwordstate_servers, {
            :'passwordstate_servers' => %i[index show],
          }, resource_type: 'PasswordstateServer'

          permission :create_passwordstate_servers, {
            :'passwordstate_servers' => %i[new create],
          }, resource_type: 'PasswordstateServer'

          permission :edit_passwordstate_servers, {
            :'passwordstate_servers' => %i[edit],
          }, resource_type: 'PasswordstateServer'

          permission :delete_passwordstate_servers, {
            :'passwordstate_servers' => %i[destroy],
          }, resource_type: 'PasswordstateServer'

          permission :full_passwordstate_password_access, {
            :'api/v2/passwords' => %i[acquire release]
          }

          # permission :view_hosts,
          #   { hosts: %i[passwordstate_passwords_tab_selected] },
          #   resource_type: 'Host'
        end

        Foreman::AccessControl.permission(:view_hosts).actions.concat %w[
          hosts/passwordstate_passwords_tab_selected
        ]

        role 'Passwordstate server viewer', %i[view_passwordstate_servers]
        role 'Passwordstate server manager', %i[view_passwordstate_servers create_passwordstate_servers edit_passwordstate_servers delete_passwordstate_servers ]

        # Only meant for a puppetmaster user, to retrieve passwords into the catalog
        role 'Password manager', %i[full_passwordstate_password_access]

        add_all_permissions_to_default_roles

        # add menu entry
        menu :top_menu, :passwordstate_servers,
             url_hash: { controller: :passwordstate_servers, action: :index },
             caption: N_('Passwordstate Servers'),
             parent: :infrastructure_menu

        register_facet :passwordstate_facet, nil do
          configure_host ForemanPasswordstate::PasswordstateHostFacet do
            # extend_model ForemanPasswordstate::HostManagedExtensions # The #root_pass override fails if done here
            add_tabs passwordstate_facet: 'foreman_passwordstate/passwordstate_facets/passwordstate_facet'
          end
          configure_hostgroup ForemanPasswordstate::PasswordstateHostgroupFacet
        end

        register_info_provider ForemanPasswordstate::HostInfoProvider

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
