require 'rails_helper'

RSpec.describe ChatChannel, type: :channel do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  before do
    stub_connection current_user: user1
    subscribe
  end

  it 'subscribes to a stream using the current user ID' do
    expect(subscription).to be_confirmed
    expect(streams).to include("user_#{user1.id}")
  end

  it 'broadcast message to the desired user' do
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

  it 'saves the message in local DB' do
    expect {
      perform :receive, to_user_id: user2.id, body: 'hello'
    }.to change { Message.count }.from(0).to(1)

    message = Message.first
    expect(message.body).to eq('hello')
    expect(message.recipient_id).to eq(user2.id)
    expect(message.author_id).to eq(user1.id)
  end
end
