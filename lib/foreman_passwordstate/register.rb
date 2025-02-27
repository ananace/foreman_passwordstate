# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Foreman::Plugin.register :foreman_passwordstate do
  requires_foreman '>= 3.12'

  apipie_documented_controllers ["#{ForemanPasswordstate::Engine.root}/app/controllers/api/v2/*.rb"]

  security_block :foreman_passwordstate do
    permission :view_passwordstate_servers, {
      passwordstate_servers: %i[index show]
    }, resource_type: 'PasswordstateServer'

    permission :create_passwordstate_servers, {
      passwordstate_servers: %i[new create]
    }, resource_type: 'PasswordstateServer'

    permission :edit_passwordstate_servers, {
      passwordstate_servers: %i[edit]
    }, resource_type: 'PasswordstateServer'

    permission :delete_passwordstate_servers, {
      passwordstate_servers: %i[destroy]
    }, resource_type: 'PasswordstateServer'

    permission :full_passwordstate_password_access, {
      'api/v2/passwords': %i[acquire release]
    }

    # permission :view_hosts,
    #   { hosts: %i[passwordstate_passwords_tab_selected] },
    #   resource_type: 'Host'
  end

  Foreman::AccessControl.permission(:view_hosts).actions << 'hosts/passwordstate_passwords_tab_selected'

  role 'Passwordstate server viewer', %i[view_passwordstate_servers]
  role 'Passwordstate server manager', %i[view_passwordstate_servers create_passwordstate_servers edit_passwordstate_servers delete_passwordstate_servers]

  # Only meant for a puppetmaster user, to retrieve passwords into the catalog
  role 'Password manager', %i[full_passwordstate_password_access]

  add_all_permissions_to_default_roles

  # add menu entry
  menu :top_menu, :passwordstate_servers,
       url_hash: { controller: :passwordstate_servers, action: :index },
       caption: N_('Passwordstate Servers'),
       parent: :infrastructure_menu

  register_facet ForemanPasswordstate::PasswordstateHostFacet, :passwordstate_facet do
    configure_host do
      # extend_model ForemanPasswordstate::HostManagedExtensions # The #root_pass override fails if done here

      add_tabs passwords: 'foreman_passwordstate/passwords_tab_pane'
      set_dependent_action :destroy
    end

    configure_hostgroup ForemanPasswordstate::PasswordstateHostgroupFacet do
      set_dependent_action :destroy
    end
  end

  register_info_provider ForemanPasswordstate::HostInfoProvider

  parameter_filter Host::Managed, passwordstate_facet_attributes: %i[passwordstate_server_id password_list_id]
  parameter_filter Hostgroup, passwordstate_facet_attributes: %i[passwordstate_server_id password_list_id]

  extend_page('hosts/show') do |ctx|
    ctx.add_pagelet(
      :main_tabs,
      name: 'Passwords',
      partial: 'foreman_passwordstate/passwords_tab_pane_content',
      onlyif: proc { |host| host.passwordstate_facet } # rubocop:disable Style/SymbolProc -- Does not work with caller
    )
  end
  %i[host hostgroup].each do |res|
    extend_page("#{res}s/_form") do |ctx|
      ctx.add_pagelet(
        :main_tab_fields,
        name: 'add_passwordstate_server_selection',
        partial: 'foreman_passwordstate/host_server_selection',
        resource_type: res
      )
    end
  end

  logger :sync, enabled: true
end
# rubocop:enable Metrics/BlockLength
