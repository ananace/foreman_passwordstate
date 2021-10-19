module ForemanPasswordstate
  class HostInfoProvider < HostInfo::Provider # inherit the base class

    # override this method according to principles specified below
    def host_info
      return {} unless host.passwordstate_facet

      # Test if host password is readable
      root_user = host.operatingsystem&.root_user || 'root'
      host.host_pass(root_user, password_hash: host.operatingsystem&.password_hash)

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
    rescue StandardError => e
      ::Logging.logger[::Foreman].error "Failed to render host_info for #{host} - #{e.class}: #{e}"
      {}
    end
  end
end
