# frozen_string_literal: true

module ForemanPasswordstate
  module HostsControllerExtensions
    extend ActiveSupport::Concern

    prepended do
      before_action :find_resource_with_passwordstate, only: %i[passwordstate_passwords_tab_selected]

      alias_method :find_resource_with_passwordstate, :find_resource
    end

    def update
      ret = super

      return ret unless host_params.dig(:passwordstate_facet_attributes, :passwordstate_server_id).empty?

      remove_passwordstate_facet

      ret
    end

    def passwordstate_server_selected
      object = @host || item_object
      passwordstate_facet = object.ensure_passwordstate_facet(save: false, **host_params[:passwordstate_facet_attributes])

      render partial: 'foreman_passwordstate/host_password_choice', locals: { item: passwordstate_facet }
    end

    def passwordstate_passwords_tab_selected
      render partial: 'foreman_passwordstate/passwords_tab_pane_content'
    rescue ActionView::Template::Error => e
      process_ajax_error e, 'fetch managed passwords'
    end

    private

    def remove_passwordstate_facet
      return unless host.passwordstate_facet

      host.remove_passwordstate_passwords!
      host.passwordstate_facet.destroy
      host.update passwordstate_facet_id: nil
    rescue StandardError => e
      logger.error "Failed to remove passwordstate facet, #{e.class}: #{e} - #{e.backtrace}"
    end

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
