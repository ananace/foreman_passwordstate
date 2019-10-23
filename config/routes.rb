Rails.application.routes.draw do
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
        get 'passwordstate_passwords'
      end
    end
    resources :discovered_hosts, only: [] do
      collection do
        post 'passwordstate_server_selected'
      end
    end
  end
end
