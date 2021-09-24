module Api
  module V2
    class PasswordsController < V2::BaseController
      include Api::Version2
      include ::ForemanPasswordstate::FindHostByClientCert

      authorize_host_by_client_cert %i[acquire release]

      before_action :find_host, only: %i[acquire release]
      before_action :find_resource, only: %i[acquire]

      def_param_group :password do
        param :user, String, required: true, desc: N_('The username of the password to request')
      end

      api :GET, '/passwords/:user', N_('Acquire a password')
      param_group :password
      param :create, :bool, required: false, desc: N_('Should the password be created if it does not exist')
      param :json, :bool, required: false, desc: N_('Retrieve the password as a JSON object')
      param :hash, String, required: false, desc: N_('The hash algorithm to use on the password')
      def acquire
        return render json: @password.attributes if password_params[:json]

        render plain: @password.password
      end

      api :DELETE, '/passwords/:user', N_('Release a password')
      param_group :password
      def release
        pw = @host.password_entry(password_params[:user], create: false)
        pw.delete
      rescue Passwordstate::NotFoundError => ex
        not_found ex
      end

      private

      def action_permission
        logger.debug "action_permission: #{params.inspect}"
        case params[:action]
        when 'release', 'acquire'
          :passwords
        else
          super
        end
      end

      def find_resource
        opts = {
          create: ActiveModel::Type::Boolean.new.cast(password_params[:create] || 'false'),
          hash_type: password_params[:hash],
          _reason: "Requested by Foreman for #{detected_host ? @host : "#{@host} by #{User.current}"}"
        }.compact

        @password = @host.password_entry(password_params[:user], opts)
      rescue Passwordstate::NotFoundError => ex
        not_found ex
        nil
      rescue StandardError => e
        Foreman::Logging.exception('Failed to acquire password', e)
        nil
      end

      def find_host
        @host = detected_host

        if User.current && !@host
          # Allow specifying host if authenticated as a superuser
          @host ||= Host::Base.find_by(certname: password_params[:certname]) if password_params[:certname]
          @host ||= Host::Base.find_by(name: password_params[:hostname]) if password_params[:hostname]
        end

        unless @host
          logger.info 'Denying access because no host could be detected.'
          if User.current
            render_error 'access_denied',
                         status: :forbidden,
                         locals: {
                           details: 'You need to either authenticate with a valid client cert or specify a unique host object by hostname or certname.'
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

      def password_params
        to_permit = %i[user create hash json]
        to_permit += %i[certname hostname] unless detected_host

        params.permit to_permit
      end
    end
  end
end
