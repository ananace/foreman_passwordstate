# frozen_string_literal: true

module ForemanPasswordstate
  module HostManagedExtensions
    extend ActiveSupport::Concern

    prepended do
      include ::Orchestration::Passwordstate

      scoped_search on: :passwordstate_server_id,
                    relation: :passwordstate_facet,
                    rename: :passwordstate_server,
                    complete_value: true,
                    only_explicit: true
    end

    def ensure_passwordstate_facet(save: true, **attrs)
      return passwordstate_facet if passwordstate_facet && attrs.empty?

      attrs = passwordstate_facet.attributes.merge(attrs) if passwordstate_facet
      attrs = hostgroup.inherited_facet_attributes(Facets.registered_facets[:passwordstate_facet]).merge(attrs) if hostgroup

      if passwordstate_facet
        f = passwordstate_facet
        f.assign_attributes attrs
      else
        f = build_passwordstate_facet attrs
      end
      f.save if save && persisted?

      f
    end

    def root_pass
      return super unless passwordstate_facet
      return 'PlaceholderDuringCreation' if !persisted? || domain.nil?

      root_user = operatingsystem&.root_user || 'root'
      host_pass(root_user, password_hash: operatingsystem&.password_hash)
    rescue StandardError => e
      fullmessage = e.to_s.tr("\n", '½')
      logger.error "Failed to get root_pass for #{self} - #{e.class}: #{fullmessage}"
      Digest::SHA256.hexdigest("#{id}-PlaceholderDueToPasswordstateError")
    end

    def crypt_root_pass
      return if passwordstate?

      super
    end
  end
end

class Host::Managed::Jail < Safemode::Jail # rubocop:disable Style/ClassAndModuleChildren
  allow :host_pass
end
