class Message < ApplicationRecord
  with_options class_name: 'User' do |options|
    options.belongs_to :author
    options.belongs_to :recipient
  end
end
