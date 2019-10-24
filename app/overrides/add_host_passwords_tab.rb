# frozen_string_literal: true

Deface::Override.new(:virtual_path => 'hosts/show',
                     :name => 'add_host_passwords_tab',
                     :insert_bottom => 'ul.nav-tabs',
                     :partial => 'foreman_passwordstate/passwords_tab')

Deface::Override.new(:virtual_path => 'hosts/show',
                     :name => 'add_host_passwords_tab_pane',
                     :insert_bottom => 'div.tab-content',
                     :partial => 'foreman_passwordstate/passwords_tab_pane')
