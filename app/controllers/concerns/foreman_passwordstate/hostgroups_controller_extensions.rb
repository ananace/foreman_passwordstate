# frozen_string_literal: true

module ForemanPasswordstate
  module HostgroupsControllerExtensions
    def update
      super

      return unless hostgroup_params.dig(:passwordstate_facet_attributes, :passwordstate_server_id).empty?
      return unless @hostgroup.passwordstate_facet

      @hostgroup.passwordstate_facet.destroy
    end

    def passwordstate_server_selected
      object = @hostgroup || item_object
      passwordstate_facet = object.passwordstate_facet || object.build_passwordstate_facet
      passwordstate_facet.passwordstate_server_id ||= hostgroup_params.dig(:passwordstate_facet_attributes, :passwordstate_server_id).empty?

      render partial: 'foreman_passwordstate/host_password_choice', locals: { item: passwordstate_facet }
    end
  end
end
