module ForemanPasswordstate
  class HostInfoProvider < HostInfo::Provider # inherit the base class

    # override this method according to principles specified below
    def host_info
      return {} unless host.passwordstate_facet

      params = { 'parameters' => {
          'passwordstate' => {
            'server' => host.passwordstate_server.name,
            'server_url' => host.passwordstate_server.url,
            'list' => host.passwordstate_password_list.title,
            'list_path' => host.passwordstate_password_list.full_path,
          }
        }
      }

      params['parameters']['admin_pw'] = host.root_pass if host.operatingsystem.family == 'Windows'
      params
    end
  end
end
