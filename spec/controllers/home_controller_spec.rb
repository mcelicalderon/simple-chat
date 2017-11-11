require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    subject { get :index }

    context 'when user is signed in' do
      let(:current_user) { create(:user) }

      before(:each) do
        sign_in(current_user)
      end

      it 'renders the index template' do
        expect(subject).to render_template(:index)
      end

      it 'assigns all users but current ordered by first and last name' do
        create_list(:user, 10)
        subject
        expect(assigns[:users]).to match_array(User.where.not(id: current_user.id).order(:first_name, :last_name))
      end
    end

    context 'when user is not signed in' do
      it 'redirects the user to the sign in page' do
        expect(subject.location).to eq(new_user_session_url)
      end
    end
  end
end
