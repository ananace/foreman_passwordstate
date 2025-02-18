module ForemanPasswordstate
  module PasswordlistEnsurance
    extend ActiveSupport::Concern

    included do
      before_validation :ensure_passwordlist
      validate :validate_passwordlist
    end

    private

    def ensure_passwordlist
      return unless passwordstate_server
      return if passwordstate_server.api_type.to_sym == :winapi

      self.password_list_id = passwordstate_server.user.to_i
    end

    def validate_passwordlist
      return unless passwordstate_server && password_list_id

      passwordstate_server.password_lists.get(password_list_id)
    rescue Passwordstate::UnauthorizedError
      errors.add(:password_list_id, 'must be owned by the chosen Passwordstate server')
    end
  end
end
