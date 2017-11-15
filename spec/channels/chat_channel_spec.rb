require 'rails_helper'

RSpec.describe ChatChannel, type: :channel do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  before do
    stub_connection current_user: user1
  end

  it 'subscribes to a stream using the current user ID' do
    subscribe

    expect(subscription).to be_confirmed
    expect(streams).to include("user_#{user1.id}")
  end

  it 'broadcast message to the desired user' do
    subscribe

    travel_to(Time.zone.now) do
      expect {
        perform :receive, to_user_id: user2.id, body: 'hello'
      }.to have_broadcasted_to("user_#{user2.id}").with(
        sent_by: user1.id,
        sent_by_full_name: user1.full_name,
        body: 'hello',
        timestamp: Time.zone.now
      )
    end
  end
end
