# frozen_string_literal: true

FactoryBot.define do
  factory :passwordstate_server, class: 'PasswordstateServer' do
    name { 'Passwordstate test' }
    url { 'https://passwordstate.localhost.localdomain' }
    api_type { 'winapi' }
    user { 'testuser' }
    password { 'testpassword' }
  end
end
