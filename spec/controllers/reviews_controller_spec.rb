require "rails_helper"

RSpec.describe "Reviews", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:booking) { create(:booking, user: user) }
  let(:request) { create(:request, status: :pending, booking: booking) }
  let!(:review) { create(:review, user: user, request: request) }

  before { sign_in user }

  describe "GET /users/:user_id/reviews" do
    it "returns success" do
      get user_reviews_path(user)
      expect(response).to have_http_status(:success)
    end

    it "assigns user reviews" do
      get user_reviews_path(user)
      expect(assigns(:reviews)).to eq([review])
    end
  end

  describe "POST /users/:user_id/reviews" do
    context "with valid params" do
      let(:valid_params) do
        { review: { rating: 5, comment: "Good!", request_id: 1, review_status: "approved" } }
      end

      it "creates a new review" do
        expect {
          post user_reviews_path(user), params: valid_params
        }.to change(Review, :count).by(1)
      end

      it "redirects to bookings with success flash" do
        post user_reviews_path(user), params: valid_params
        expect(response).to redirect_to(user_bookings_path(user))
        expect(flash[:success]).to eq(I18n.t("reviews.create.success"))
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { review: { rating: nil, comment: "" } } }

      it "does not create a new review" do
        expect {
          post user_reviews_path(user), params: invalid_params
        }.not_to change(Review, :count)
      end

      it "renders error flash" do
        post user_reviews_path(user), params: invalid_params
        expect(flash[:error]).to eq(I18n.t("reviews.create.error"))
      end
    end
  end

  describe "DELETE /users/:user_id/reviews/:id" do
    context "when destroy succeeds" do
      it "deletes the review" do
        expect {
          delete user_review_path(user, review)
        }.to change(Review, :count).by(-1)
      end

      it "redirects with success flash" do
        delete user_review_path(user, review)
        expect(response).to redirect_to(user_reviews_path(user))
        expect(flash[:success]).to eq(I18n.t("reviews.destroy.success"))
      end
    end

    context "when destroy fails" do
      before do
        allow_any_instance_of(Review).to receive(:destroy).and_return(false)
      end

      it "does not delete review" do
        expect {
          delete user_review_path(user, review)
        }.not_to change(Review, :count)
      end

      it "redirects with error flash" do
        delete user_review_path(user, review)
        expect(flash[:error]).to eq(I18n.t("reviews.destroy.error"))
      end
    end
  end
end
