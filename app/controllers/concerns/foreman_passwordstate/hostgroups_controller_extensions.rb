module ForemanPasswordstate
  module HostgroupsControllerExtensions
    def update
      super

      return unless hostgroup_params.dig(:passwordstate_facet_attributes, :passwordstate_server_id).empty?
      return unless @hostgroup.passwordstate_facet

      @hostgroup.passwordstate_facet.destroy
    end

    def passwordstate_server_selected
      host = @hostgroup || item_object
      passwordstate_facet = host.passwordstate_facet || host.build_passwordstate_facet
      passwordstate_facet.passwordstate_server_id ||= (params[:passwordstate_facet] || params[:hostgroup])[:passwordstate_server_id]

      logger.debug passwordstate_facet.inspect

      render partial: 'foreman_passwordstate/host_password_choice', locals: { item: passwordstate_facet }
    end
  end
end

