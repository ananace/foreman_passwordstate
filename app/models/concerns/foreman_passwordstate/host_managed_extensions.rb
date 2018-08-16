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
      # Just to not thoroughly hammer the passwordstate server
      Rails.cache.fetch("#{cache_key}/root_pass", expires_in: 1.minute) do
        pw = host_pass('root')
        alg = operatingsystem&.password_hash || 'SHA256'
        if alg == 'Base64'
          pw = PasswordCrypt.passw_crypt(pw.password, alg)
        else
          seed = "#{cache_key}/#{pw.title}-#{pw.password_id}"
          rand = Random.new(seed.hash)
          pw = pw.password.crypt("#{PasswordCrypt::ALGORITHMS[alg]}#{Base64.strict_encode64(rand.bytes(6))}")
        end
        pw.force_encoding(Encoding::UTF_8) if pw.encoding != Encoding::UTF_8
        pw
      end
    end
  end
end
