# frozen_string_literal: true

module Orchestration
  module Passwordstate
    extend ActiveSupport::Concern

    included do
      # TODO?
      # after_build :ensure_passwordstate_host, if: :passwordstate?
      # before_provision :remove_passwordstate_host, if: :passwordstate?

      before_destroy :remove_passwordstate_passwords!, if: :passwordstate?
      # TODO: Remove passwords from old list if list ID is changing
      # before_update :remove_outdated_passwords, if: :passwordstate?
      after_update :ensure_passwordstate_passwords, if: :saved_change_to_name?
    end

    delegate :passwordstate_server, to: :passwordstate_facet
    delegate :password_list, to: :passwordstate_facet, prefix: :passwordstate

    def passwordstate?
      !passwordstate_facet.nil?
    end

    def host_pass(username, password_hash: nil, create: true, **params)
      return nil unless passwordstate?

      password_hash ||= 'None'
      raise ArgumentError, 'Unknown password hash algorithm' if password_hash != 'None' && !PasswordCrypt::ALGORITHMS.key?(password_hash)

      # As template renders read the root password multiple times,
      # add a short cache to not hammer the passwordstate server
      ForemanPasswordstate::PasswordstatePasswordsCache.instance.fetch("#{cache_key}/pass-#{username}/#{password_hash}", expires_in: 60.minutes) do
        pw = password_entry(username, create: create, **params)
        case password_hash
        when 'None'
          pw = pw.password
        when 'Base64', 'Base64-Windows'
          pw = PasswordCrypt.passw_crypt(pw.password, password_hash)
        else
          seed = [
            pw.password_id, passwordstate_facet.password_list_id,
            passwordstate_facet.id, id, passwordstate_server.id
          ].join ':'
          seed = Base64.strict_encode64(Digest::SHA1.digest(seed)).gsub(%r{[^a-zA-Z0-9./]}, '.')
          pw = pw.password.crypt("#{PasswordCrypt::ALGORITHMS[password_hash]}#{seed}")
        end
        pw.force_encoding(Encoding::UTF_8) if pw.encoding != Encoding::UTF_8
        pw
      end
    end

    def passwordstate_passwords
      passwordstate_password_list(_bare: true)
        .passwords
        .search(description: stable_pw_desc, exclude_password: true)
        .select { |e| e.description.ends_with? stable_pw_desc }
    end

    private

    def stable_pw_desc
      " #{id}:#{passwordstate_server.id}/foreman"
    end

    def password_entry(username, create: true, **params)
      list = passwordstate_password_list(_bare: true)

      # TODO: If Hosts enabled
      # pw = list.search(host_name: name, user_name: 'root')

      pw_desc = "Foreman managed password for #{username} on #{fqdn} | #{stable_pw_desc.strip}"
      begin
        pw = list.passwords.search(**params, description: stable_pw_desc, user_name: username).select { |e| e.description.ends_with? stable_pw_desc }.first
        pw ||= list.passwords.create(**params, title: "#{username}@#{fqdn}", description: pw_desc, user_name: username, generate_password: true) if create

        pw
      rescue ::Passwordstate::NotFoundError
        return list.passwords.create(**params, title: "#{username}@#{fqdn}", description: pw_desc, user_name: username, generate_password: true) if create

        raise
      end
    end

    def passwordstate_facet_empty?
      return false if passwordstate_facet&.passwordstate_server_id
      return false if passwordstate_facet&.password_list_id

      true
    end

    def ensure_passwordstate_passwords
      return unless passwordstate_facet

      ::Foreman::Logging
        .logger('foreman_passwordstate/sync')
        .info 'Ensuring Passwordstate passwords are up-to-date...'

      passwordstate_passwords.each do |password|
        password.title = "#{password.user_name}@#{fqdn}"
        password.description = "Foreman managed password for #{password.user_name} on #{fqdn} | #{stable_pw_desc.strip}"
        next unless password.send(:modified).any?

        password.put
      end

      true
    end

    def remove_passwordstate_passwords!
      return unless passwordstate_facet

      ::Foreman::Logging
        .logger('foreman_passwordstate/sync')
        .info 'Removing Passwordstate passwords...'

      passwordstate_passwords.each(&:delete)
      true
    rescue ::Passwordstate::NotFoundError
      true
    end
  end
end
