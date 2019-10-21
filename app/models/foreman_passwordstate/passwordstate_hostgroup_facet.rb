module ForemanPasswordstate
  class PasswordstateHostgroupFacet < ApplicationRecord
    include Facets::HostgroupFacet

    belongs_to :passwordstate_server,
               class_name: '::PasswordstateServer',
               inverse_of: :passwordstate_facets

    validates_lengths_from_database

    validates :hostgroup, presence: true, allow_blank: false
    validates :passwordstate_server, presence: true, allow_blank: false

    # inherit_attributes :passwordstate_server_id, :password_list_id
    def self.attributes_to_inherit
      %w[passwordstate_server_id password_list_id]
    end

    def password_list
      return nil unless password_list_id

      passwordstate_server.password_lists.get(password_list_id)
    end
  end
end
