Deface::Override.new(virtual_path:  'hosts/_form',
                     name:          'add_passwordstate_server_selection',
                     insert_bottom: '#primary',
                     partial:       'foreman_passwordstate/host_server_selection')

Deface::Override.new(virtual_path: 'hosts/_operating_system',
                     name:         'add_passwordstate_password_choice',
                     insert_after: '#root_password',
                     partial:      'foreman_passwordstate/host_password_choice')

# Hostgroup facets are not implemented at the moment
if Hostgroup.instance_methods.include? :build_passwordstate_facet
  Deface::Override.new(virtual_path:  'hostgroups/_form',
                       name:          'hg_add_passwordstate_server_selection',
                       insert_bottom: '#primary',
                       partial:       'foreman_passwordstate/host_server_selection')

  Deface::Override.new(virtual_path:  'hostgroups/_form',
                       name:          'hg_add_passwordstate_password_choice',
                       insert_bottom: '#os',
                       partial:       'foreman_passwordstate/host_password_choice')
end
