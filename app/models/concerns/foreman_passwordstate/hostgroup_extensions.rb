module ForemanPasswordstate
  module HostgroupExtensions
    def self.prepended(base)
      base.class_eval do
        has_one :passwordstate_facet,
                class_name: '::ForemanPasswordstate::PasswordstateHostgroupFacet',
                foreign_key: :hostgroup_id,
                inverse_of: :hostgroup,
                dependent: :destroy
      end
    end

    delegate :passwordstate_server, to: :passwordstate_facet
    delegate :password_list, to: :passwordstate_facet, prefix: :passwordstate

    def ensure_passwordstate_facet(force_inherit: false, **attrs)
      return passwordstate_facet if passwordstate_facet && attrs.empty? && !force_inherit

      if force_inherit
        attrs = parent.inherited_facet_attributes(Facets.registered_facets[:passwordstate_facet]).merge(attrs) if parent
        attrs = passwordstate_facet.attributes.merge(attrs) if passwordstate_facet
      else
        attrs = passwordstate_facet.attributes.merge(attrs) if passwordstate_facet
        attrs = parent.inherited_facet_attributes(Facets.registered_facets[:passwordstate_facet]).merge(attrs) if parent
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
  end
end
