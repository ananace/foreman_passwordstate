module Foreman::Controller::Parameters::PasswordstateServer
  extend ActiveSupport::Concern

  class_methods do
    def passwordstate_server_params_filter
      Foreman::ParameterFilter.new(::PasswordstateServer).tap do |filter|
        filter.permit :name,
                      :description,
                      :url,
                      :api_type,
                      :user,
                      :password,
                      :apikey
      end
    end
  end

  def passwordstate_server_params
    self.class.passwordstate_server_params_filter.filter_params(params, parameter_filter_context, :passwordstate_server)
  end
end
