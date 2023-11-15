# frozen_string_literal: true

Deface::Override.new(virtual_path: 'hosts/_operating_system',
                     name: 'add_host_passwordstate_password_choice',
                     insert_after: '#root_password',
                     partial: 'foreman_passwordstate/host_password_choice')
