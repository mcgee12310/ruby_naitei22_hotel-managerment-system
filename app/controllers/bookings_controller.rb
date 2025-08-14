class BookingsController < ApplicationController
  before_action :require_login, only: [:index, :update_request]

  def index
    @bookings = current_user.bookings.includes(:requests)
  end

  def update_request
    @booking = current_user.bookings.find(params[:id])

    if @booking.update(booking_params)
      create_room_availability_requests(@booking)
      flash[:success] = t(".add_request_success")
      redirect_to bookings_path
    else
      flash[:danger] = @booking.errors.full_messages.to_sentence
      redirect_back fallback_location: root_path
    end
  end

  private

  def create_room_availability_requests(booking)
    req = booking.requests.last
    return unless req # đảm bảo có request

     booking_dates = (req.check_in.to_date..req.check_out.to_date).to_a

    room_avails = req.room.room_availabilities
                      .where(available_date: booking_dates)

    room_avails.each do |avail|
      req.room_availability_requests.create!(
        room_availability: avail
      )
    end
  end

  def require_login
    return if logged_in?

    flash[:danger] = t("bookings.card.need_login")
    redirect_to login_path
  end

  def booking_params
    params.require(:booking).permit(
      requests_attributes: [:room_id, :check_in, :check_out, :number_of_guests,
:note]
    )
  end
end
