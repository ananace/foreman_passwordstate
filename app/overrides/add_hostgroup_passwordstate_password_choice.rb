# frozen_string_literal: true

Deface::Override.new(virtual_path: 'hostgroups/_form',
                     name: 'add_hostgroup_passwordstate_password_choice',
                     insert_bottom: '#os',
                     partial: 'foreman_passwordstate/host_password_choice')
