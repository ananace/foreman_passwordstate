module ForemanPasswordstate
  class PasswordstateFacet < ApplicationRecord
    include Facets::Base

    belongs_to :passwordstate_server,
               class_name: '::PasswordstateServer',
               inverse_of: :passwordstate_facets

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false
    validates :passwordstate_server, presence: true, allow_blank: false

    def password_list
      return nil unless password_list_id

      passwordstate_server.password_lists.get(password_list_id)
    end
  end
end
