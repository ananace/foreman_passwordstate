Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    scope '(:apiv)', module: :v2,
                     defaults: { apiv: 'v2' },
                     apiv: /v1|v2/,
                     constraints: ApiConstraints.new(version: 2) do
      get 'passwords/:user', to: 'passwords#acquire'
      delete 'passwords/:user', to: 'passwords#release'
    end
  end

  scope '/foreman_passwordstate' do
    constraints(id: %r{[^\/]+}) do
      resources :passwordstate_servers do
        collection do
          get 'auto_complete_search'
          post 'test_connection'
        end
        member do
          get 'folders'
          get 'password_lists'
        end
      end
    end
  end

  constraints(id: %r{[^\/]+}) do
    resources :hostgroups, only: [] do
      collection do
        post 'passwordstate_server_selected'
      end
    end
    resources :hosts, only: [] do
      collection do
        post 'passwordstate_server_selected'
      end
      member do
        get 'passwordstate_passwords_tab_selected'
      end
    end
    resources :discovered_hosts, only: [] do
      collection do
        post 'passwordstate_server_selected'
      end
    end
  end
end
