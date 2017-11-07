FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "email#{n}@domain.com" }
    password   'password'
    first_name 'Vincent'
    last_name  'Vega'
    confirmed_at Time.current
    last_sign_in_at Time.current
  end
end
