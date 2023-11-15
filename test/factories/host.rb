# frozen_string_literal: true

FactoryBot.modify do
  factory :host do
    trait :with_passwordstate_facet do
      association :passwordstate_facet, factory: :passwordstate_host_facet, strategy: :build
    end
  end
end
