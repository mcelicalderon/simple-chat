FactoryGirl.define do
  factory :user do
    sequence(:email)      { |n| "email#{n}@domain.com" }
    password              'password'
    sequence(:first_name) { |n| "Vincent#{n}" }
    sequence(:last_name)  { |n| "Vega#{n}" }
    confirmed_at          Time.current
    last_sign_in_at       Time.current
  end
end
