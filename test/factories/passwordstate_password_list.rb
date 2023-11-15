# frozen_string_literal: true

FactoryBot.define do
  factory :passwordstate_password_list, class: 'Passwordstate::Resources::PasswordList' do
    skip_create

    sequence(:password_list_id)
    password_list { 'Test' }
    tree_path { '\\Passwords' }

    initialize_with do
      new password_list_id: password_list_id,
          password_list: password_list,
          tree_path: tree_path
    end
  end
end
