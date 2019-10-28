module ForemanPasswordstate
  module HostsControllerExtensions
    def self.prepended(base)
      base.class_eval do
        before_action :find_resource_with_passwordstate, only: %i[passwordstate_passwords_tab_selected]

        alias_method :find_resource_with_passwordstate, :find_resource
      end
    end

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

    def passwordstate_passwords_tab_selected
      render partial: 'foreman_passwordstate/passwords_tab_pane_content'
    rescue ActionView::Template::Error => exception
      process_ajax_error exception, 'fetch managed passwords'
    end

    private

    def action_permission
      case params[:action]
      when 'passwordstate_passwords_tab_selected'
        :view
      when 'passwordstate_server_selected'
        :edit
      else
        super
      end
    end
  end
end

