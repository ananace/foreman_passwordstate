module ForemanPasswordstate
  module HostManagedExtensions
    def self.prepended(base)
      base.class_eval do
        # TODO
        # after_build :ensure_passwordstate_host
        # before_provision :remove_passwordstate_host

        has_one :passwordstate_facet,
                class_name: '::ForemanPasswordstate::PasswordstateHostFacet',
                foreign_key: :host_id,
                inverse_of: :host,
                dependent: :destroy

        scoped_search on: :passwordstate_server_id,
                      relation: :passwordstate_facet,
                      rename: :passwordstate_server,
                      complete_value: true,
                      only_explicit: true

        before_destroy :remove_passwordstate_passwords!
        # after_update :ensure_passwordstate_passwords
      end
    end

    delegate :passwordstate_server, to: :passwordstate_facet
    delegate :password_list, to: :passwordstate_facet, prefix: :passwordstate

    def ensure_passwordstate_facet(force_inherit: false, **attrs)
      return passwordstate_facet if passwordstate_facet && attrs.empty? && !force_inherit

      if force_inherit
        attrs = hostgroup.inherited_facet_attributes(Facets.registered_facets[:passwordstate_facet]).merge(attrs) if hostgroup
        attrs = passwordstate_facet.attributes.merge(attrs) if passwordstate_facet
      else
        attrs = passwordstate_facet.attributes.merge(attrs) if passwordstate_facet
        attrs = hostgroup.inherited_facet_attributes(Facets.registered_facets[:passwordstate_facet]).merge(attrs) if hostgroup
      end

      if passwordstate_facet
        f = passwordstate_facet
        f.update_attributes attrs
      else
        f = build_passwordstate_facet attrs
      end
      f.save if persisted?

      f
    end

    # FIXME
    def serializable_hash(options = nil)
      return super unless passwordstate_facet
      return super unless caller.include? "/usr/share/foreman/app/controllers/api/v2/hosts_controller.rb:289:in `facts'"

      # Skip writing root_pass in the serialized object
      options ||= {}
      if !options[:only]
        options[:except] ||= []
        options[:except] << :root_pass
      end

      super options
    end

    def password_entry(username, create: true, **params)
      return nil unless passwordstate_facet

      list = passwordstate_password_list(_bare: true)

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

    def passwordstate_passwords
      return nil unless passwordstate_facet

      stable_pw_desc = "#{id}:#{passwordstate_server.id}/foreman"
      passwordstate_password_list(_bare: true).passwords.search(description: "#{id}:#{passwordstate_server.id}/foreman", exclude_password: true)
    end


    def host_pass(username, password_hash: 'SHA256', create: true, **params)
      return nil unless passwordstate_facet

      password_hash ||= 'SHA256'
      raise ArgumentError, 'Unknown password hash algorithm' unless PasswordCrypt::ALGORITHMS.key? password_hash

      # As template renders read the root password multiple times,
      # add a short cache just to not thoroughly hammer the passwordstate server
      PasswordstatePasswordsCache.instance.fetch("#{cache_key}/pass-#{username}/#{password_hash}", expires_in: 30.minutes) do
        pw = password_entry(username, create: create, **params)
        if password_hash == 'Base64'
          pw = PasswordCrypt.passw_crypt(pw.password, password_hash)
        elsif password_hash == 'None'
          pw = pw.password
        else
          seed = "#{passwordstate_facet.id}:#{id}@#{passwordstate_server.id}/#{passwordstate_facet.password_list_id}/#{pw.password_id}"
          pw = pw.password.crypt("#{PasswordCrypt::ALGORITHMS[password_hash]}#{Base64.strict_encode64(Digest::SHA1.digest(seed))}")
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

      logger.info "Removing Passwordstate passwords..."

      passwordstate_passwords.each(&:delete)
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
