# frozen_string_literal: true

FactoryBot.define do
  factory :passwordstate_host_facet, class: 'ForemanPasswordstate::PasswordstateHostFacet' do
    host

    passwordstate_server
    password_list_id { 5 }
  end
end
