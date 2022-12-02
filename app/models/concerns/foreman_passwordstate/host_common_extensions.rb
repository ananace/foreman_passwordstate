# frozen_string_literal: true

module ForemanPasswordstate
  module HostCommonExtensions
    def crypt_root_pass
      return if !is_a?(Hostgroup) && passwordstate_facet

      super
    end
  end
end
