class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  with_options class_name: 'Message', dependent: :nullify do |options|
    options.has_many :outgoing_messages, foreign_key: 'author_id'
    options.has_many :incoming_messages, foreign_key: 'recipient_id'
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
