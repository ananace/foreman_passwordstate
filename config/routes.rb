Rails.application.routes.draw do
  scope '/foreman_passwordstate' do
    constraints(id: %r{[^\/]+}) do
      resources :passwordstate_servers do
        collection do
          get 'auto_complete_search'
          post 'test_connection'
        end
      end
    end
  end
end
