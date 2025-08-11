class BookingsController < ApplicationController
  before_action :require_login, only: [:index, :update]

  def index
    @bookings = current_user.bookings.includes(:requests)
  end

  def update
    @booking = current_user.bookings.find(params[:id])
    if @booking.update(booking_params)
      redirect_to bookings_path, notice: "Đã thêm phòng vào giỏ hàng"
    else
      flash[:danger] = @booking.errors.full_messages.to_sentence
      redirect_back fallback_location: root_path
    end
  end

  private

  def booking_params
    params.require(:booking).permit(
      requests_attributes: [:room_id, :check_in, :check_out, :number_of_guests,
:note]
    )
  end

  def require_login
    return if logged_in?

    flash[:danger] = "Bạn cần đăng nhập để tiếp tục"
    redirect_back(fallback_location: root_path) and return
  end
end
