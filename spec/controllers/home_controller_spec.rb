require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    subject { get :index }

    context 'when user is signed in' do
      before(:each) do
        sign_in create(:user)
      end

      it 'renders the index template' do
        expect(subject).to render_template(:index)
      end
    end

    context 'when user is not signed in' do
      it 'redirects the user to the sign in page' do
        expect(subject.location).to eq(new_user_session_url)
      end
    end
  end
end
