class BookingsController < ApplicationController
  before_action :require_login, only: [:index, :update_request]
  before_action :set_current_booking,
                only: [:current_booking, :update_request, :confirm_booking]

  def index
    @bookings = current_user.bookings.includes(:requests)
  end

  def update_request
    if @current_booking.update(booking_params)
      create_room_availability_requests(@current_booking)
      flash[:success] = t(".add_request_success")
      redirect_to current_booking_bookings_path
    else
      flash[:danger] = @current_booking.errors.full_messages.to_sentence
      redirect_back fallback_location: root_path
    end
  end

  def destroy
    @booking = current_user.bookings.find(params[:id])

    if @booking.destroy
      flash[:success] = t(".success")
    else
      flash[:danger] = t(".failure")
    end

    redirect_to current_booking_bookings_path
  end

  def current_booking
    if @current_booking
      render :current_booking
    else
      redirect_to bookings_path
    end
  end

  def confirm_booking
    overlaps = find_overlapping_requests

    if overlaps.blank?
      assign_booking_code_and_status
      flash[:success] = t("current_booking.confirm.success")
      redirect_to bookings_path
    else
      redirect_if_overlap overlaps
    end
  end

  private

  def create_room_availability_requests booking
    req = booking.requests.last
    return unless req

    booking_dates = (req.check_in.to_date..req.check_out.to_date).to_a

    room_avails = req.room.room_availabilities
                     .where(available_date: booking_dates)

    room_avails.each do |avail|
      req.room_availability_requests.create!(
        room_availability: avail
      )
    end
  end

  def redirect_if_overlap overlaps
    return unless overlaps.any?

    room_names = overlaps.map {|r| r.room.room_number }.uniq.join(", ")
    flash[:warning] =
      t("current_booking.confirm.overlap_with_rooms", rooms: room_names)
    redirect_to @current_booking
    true
  end

  def find_overlapping_requests
    invalid_statuses = %i(draft declined cancelled)

    @current_booking.requests.select do |req|
      Request
        .where(room_id: req.room_id)
        .where.not(id: req.id)
        .where.not(status: invalid_statuses)
        .where("(check_in <= ? AND check_out >= ?)",
               req.check_out, req.check_in)
        .exists?
    end
  end

  def assign_booking_code_and_status
    random_code = SecureRandom.alphanumeric(6).upcase
    @current_booking.update!(booking_code: random_code, status: :pending)
    @current_booking.requests.update_all(status: :pending)
  end

  def set_current_booking
    return unless logged_in?

    @current_booking = current_user.bookings.find_or_create_by(status: :draft)
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
