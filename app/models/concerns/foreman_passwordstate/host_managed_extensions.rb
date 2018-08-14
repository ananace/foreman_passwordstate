module ForemanPasswordstate
  module HostManagedExtensions
    def self.prepended(base)
      base.class_eval do
        # TODO
        # after_build :ensure_passwordstate_host
        # before_provision :remove_passwordstate_host

        has_one :passwordstate_facet,
                class_name: '::ForemanPasswordstate::PasswordstateFacet',
                foreign_key: :host_id,
                inverse_of: :host,
                dependent: :destroy
      end
    end

    delegate :passwordstate_server, to: :passwordstate_facet
    delegate :password_list, to: :passwordstate_facet, prefix: :passwordstate


    def host_pass(username, create = true)
      return super unless passwordstate_facet
      list = passwordstate_password_list

      # TODO: If Hosts enabled
      # pw = list.search(host_name: name, user_name: 'root')

      begin
        list.passwords.search(title: "#{username}@#{name}", user_name: username).first
      rescue Passwordstate::NotFoundError
        list.passwords.create title: "#{username}@#{name}", user_name: username, generate_password: true if create
      end
    end

    def root_pass
      pw = host_pass('root')
      operatingsystem.nil? ? PasswordCrypt.passw_crypt(pw.password) : PasswordCrypt.passw_crypt(pw.password, operatingsystem.password_hash)
    end
  end
end
