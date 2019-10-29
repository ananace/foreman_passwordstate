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

    # Example;
    # 
    # Base - Hostgroup, has facet, value: "1"
    #
    # Base/Child - Hostgroup, no facet
    # Base/Child/Subchild - Hostgroup, no facet
    #
    # Base/Child2 - Hostgroup, has facet, value: nil
    # Base/Child2/Subchild - Hostgroup, has facet, value: "2"
    #
    # Host in Base/Child will inherit "1"
    # Host in Base/Child/Subchild will inherit "1"
    # Host in Base/Child2 will not inherit anything
    # Host in Base/Child2/Subchild will inherit "2"

    def inherited_facet_attributes(facet_config)
      return super unless facet_config.name == :passwordstate_facet

      inherited_attributes = send(facet_config.name)&.inherited_attributes || {}

      hostgroup_ancestry_cache.reverse_each do |hostgroup|
        hg_facet = hostgroup.send(facet_config.name)
        next unless hg_facet
        inherited_attributes.merge!(hg_facet.inherited_attributes) { |key, _l, _r| !inherited_attributes.key? key }
      end

      inherited_attributes
    end
  end
end
