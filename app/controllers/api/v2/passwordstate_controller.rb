module Api
  module V2
    class PasswordstateController < V2::BaseController
      include Api::Version2
      include ::ForemanPasswordstate::FindHostByClientCert

      authorize_host_by_client_cert %i[acquire]

      before_action :find_host, only: %i[acquire]
      before_action :find_resource, only: %i[acquire]

      def_param_group :passwordstate do
        param :user, String, required: true, desc: N_('The username of the password to request')
      end

      api :GET, '/passwordstate/:user', N_('Acquire a Passwordstate password')
      param_group :passwordstate
      param :create, Boolean, required: false, desc: N_('Should the password be created if it does not exist')
      param :hash, String, required: false, desc: N_('The hash algorithm to use on the password')

      def acquire
        
      end

      def resource_class
        Host::Managed
      end

      def action_permission
        case params[:action]
        when 'release', 'acquire'
          :edit
        else
          super
        end
      end

      def find_resource
        @password = @host.passwordstate_entry(params[:user], create: ActiveModel::Type::Boolean.new.cast(params[:create] || 'false'))
      end

      def find_host
        @host = detected_host
        unless @host
          logger.info 'Denying access because no host could be detected.'
          if User.current
            render_error 'access_denied',
                         status: :forbidden,
                         locals: {
                           details: 'You need to authenticate with a valid client cert. The DN has to match a known host.'
                         }
          else
            render_error 'unauthorized',
                         status: :unauthorized,
                         locals: {
                           user_login: get_client_cert_hostname
                         }
          end
        end
        true
      end
    end
  end
end
