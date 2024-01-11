# frozen_string_literal: true

module ForemanPasswordstate
  class PasswordstateHostFacet < ApplicationRecord
    include Facets::Base

    belongs_to :passwordstate_server,
               class_name: '::PasswordstateServer',
               inverse_of: :passwordstate_host_facets

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false
    validates :passwordstate_server, presence: true, allow_blank: false
    validates :password_list_id, presence: true, allow_blank: false

    def password_list(**query)
      passwordstate_server.password_lists.get(password_list_id, **query)
    end

    # FOREMAN-37043
    def self.inherited_attributes(hostgroup, facet_attributes)
      facet_attributes.merge(super) { |_, left, right| left || right }
    end
  end
end
