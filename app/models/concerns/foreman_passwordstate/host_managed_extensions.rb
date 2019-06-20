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

        before_destroy :remove_passwordstate_passwords!
        # after_update :ensure_passwordstate_passwords
      end
    end

    delegate :passwordstate_server, to: :passwordstate_facet
    delegate :password_list, to: :passwordstate_facet, prefix: :passwordstate

    def password_entry(username, create: true, **params)
      return nil unless passwordstate_facet

      list = passwordstate_password_list

      # TODO: If Hosts enabled
      # pw = list.search(host_name: name, user_name: 'root')

      stable_pw_desc = "#{id}:#{passwordstate_server.id}/foreman"
      pw_desc = "Foreman managed password for #{username} on #{fqdn} | #{stable_pw_desc}"
      begin
        list.passwords.search(params.merge(description: stable_pw_desc, user_name: username)).first
      rescue Passwordstate::NotFoundError => e
        return list.passwords.create params.merge(title: "#{username}@#{fqdn}", description: pw_desc, user_name: username, generate_password: true) if create

        raise e
      end
    end

    def host_pass(username, password_hash: 'SHA256', create: true, **params)
      return nil unless passwordstate_facet

      # As template renders read the root password multiple times,
      # add a short cache just to not thoroughly hammer the passwordstate server
      PasswordstateCache.instance.fetch("#{cache_key}/pass-#{username}", expires_in: 1.minute) do
        pw = password_entry(username, create: create, **params)
        alg = password_hash || 'SHA256'
        if alg == 'Base64'
          pw = PasswordCrypt.passw_crypt(pw.password, alg)
        elsif alg == 'None'
          pw = pw.password
        else
          seed = "#{passwordstate_facet.id}:#{id}@#{passwordstate_server.id}/#{passwordstate_facet.password_list_id}/#{pw.password_id}"
          pw = pw.password.crypt("#{PasswordCrypt::ALGORITHMS[alg]}#{Base64.strict_encode64(Digest::SHA1.digest(seed))}")
        end
        pw.force_encoding(Encoding::UTF_8) if pw.encoding != Encoding::UTF_8
        pw
      end
    end

    def root_pass
      return super unless passwordstate_facet

      return 'PlaceholderDuringCreation' if !persisted? || domain.nil?

      root_user = operatingsystem&.root_user || 'root'
      host_pass(root_user, password_hash: operatingsystem&.password_hash)
    end

    def remove_passwordstate_passwords!
      return unless passwordstate_facet

      passwordstate_password_list.passwords.search(description: "#{id}:#{passwordstate_server.id}/foreman").each(&:delete)
      true
    rescue Passwordstate::NotFoundError
      true
    end

    # Skip encrypting the root password if it's read from passwords
    def crypt_root_pass
      return if passwordstate_facet

      super
    end

  end
end
