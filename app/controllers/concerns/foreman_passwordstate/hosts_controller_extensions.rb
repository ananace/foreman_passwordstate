module ForemanPasswordstate
  module HostsControllerExtensions
    def update
      super

      return unless host_params.dig(:passwordstate_facet_attributes, :passwordstate_server_id).empty?
      return unless @host.passwordstate_facet

      @host.remove_passwordstate_passwords!
      @host.passwordstate_facet.destroy
    end

    def passwordstate_server_selected
      host = @host || item_object
      passwordstate_facet = host.passwordstate_facet || host.build_passwordstate_facet
      passwordstate_facet.passwordstate_server_id ||= (params[:passwordstate_facet] || params[:host])[:passwordstate_server_id]

      render partial: 'foreman_passwordstate/host_password_choice', locals: { item: passwordstate_facet }
    end
  end
end

