module ForemanPasswordstate
  module HostgroupExtensions
    def self.prepended(base)
      base.class_eval do
        has_one :passwordstate_facet,
                class_name: '::ForemanPasswordstate::PasswordstateFacet',
                dependent: :destroy
      end
    end

    delegate :passwordstate_server, to: :passwordstate_facet
    delegate :password_list, to: :passwordstate_facet, prefix: :passwordstate
  end
end