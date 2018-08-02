module ForemanPasswordstate
  class PasswordstateFacet < ApplicationRecord
    include Facets::Base

    belongs_to :passwordstate_server,
               class_name: '::PasswordstateServer',
               inverse_of: :passwordstate_facets

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false

    # TODO: Per-host Password lists?
  end
end

