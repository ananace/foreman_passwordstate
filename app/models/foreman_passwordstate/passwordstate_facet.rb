module ForemanPasswordstate
  class PasswordstateFacet < ApplicationRecord
    include Facets::HostgroupFacet
    include Facets::Base

    belongs_to :passwordstate_server,
               class_name: '::PasswordstateServer',
               inverse_of: :passwordstate_facets

    validates_lengths_from_database

    # validates :host, presence: true, allow_blank: false
    validates :passwordstate_server, presence: true, allow_blank: false

    before_save :temporary_hack

    def password_list
      return nil unless password_list_id

      passwordstate_server.password_lists.get(password_list_id)
    end

    def temporary_hack
      logger.debug "TODO: Fix this properly."

      hostgroup_id = nil unless host_id.nil?
    end
  end
end
