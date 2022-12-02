# frozen_string_literal: true

module ForemanPasswordstate
  class PasswordstateHostgroupFacet < ApplicationRecord
    include Facets::HostgroupFacet

    belongs_to :passwordstate_server,
               class_name: '::PasswordstateServer',
               inverse_of: :passwordstate_hostgroup_facets

    validates_lengths_from_database

    validates :hostgroup, presence: true, allow_blank: false
    validates :passwordstate_server, presence: true, allow_blank: false

    class << self
      def attributes_to_inherit
        @attributes_to_inherit ||= attribute_names - %w[id created_at updated_at hostgroup_id]
      end
    end

    inherit_attributes(*%w[passwordstate_server_id password_list_id])

    def password_list(**query)
      return nil unless password_list_id

      passwordstate_server.password_lists.get(password_list_id, **query)
    end
  end
end
