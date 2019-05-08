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

    def password_entry(username, create: true, **params)
      return nil unless passwordstate_facet

      list = passwordstate_password_list

      # TODO: If Hosts enabled
      # pw = list.search(host_name: name, user_name: 'root')

      begin
        list.passwords.search(params.merge(title: "#{username}@#{name}", user_name: username)).first
      rescue Passwordstate::NotFoundError => e
        return list.passwords.create params.merge(title: "#{username}@#{name}", user_name: username, generate_password: true) if create

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
          seed = "#{uuid || id}/#{pw.title}-#{pw.password_id}"
          rand = Random.new(seed.hash)
          pw = pw.password.crypt("#{PasswordCrypt::ALGORITHMS[alg]}#{Base64.strict_encode64(rand.bytes(6))}")
        end
        pw.force_encoding(Encoding::UTF_8) if pw.encoding != Encoding::UTF_8
        pw
      end
    end

    def root_pass
      return super unless passwordstate_facet

      host_pass('root', password_hash: operatingsystem&.password_hash)
    end
  end
end
