class RoomsController < ApplicationController
  before_action :set_current_booking

  def index
    @pagy, @rooms = pagy Room.includes(:room_type)
    filter_by_room_type
    filter_by_price_range
    sort_rooms
  end

  def show
    @room = Room.find(params[:id])
    @amenities = @room.amenities
    @reviews = @room.reviews.includes(:user)
    @available_dates = @room.available_dates

    @booking = current_user&.bookings&.find_by(status: "draft") || Booking.new
    @booking.requests.build(room: @room)
  end

  def calculate_price
    room = Room.find(params[:id])
    check_in = begin
      Date.parse(params[:check_in])
    rescue StandardError
      nil
    end
    check_out = begin
      Date.parse(params[:check_out])
    rescue StandardError
      nil
    end

    if check_in && check_out && check_out >= check_in
      nights = (check_out - check_in).to_i
      total_price = room.room_availabilities
                        .where(available_date: check_in..check_out)
                        .sum(:price)

      render json: {total_price:, nights:}
    else
      render json: {total_price: nil, nights: nil}
    end
  end

  private

  def filter_by_room_type
    return if params[:room_type].blank?

    @rooms = @rooms.joins(:room_type)
                   .where(room_types: {name: params[:room_type]})
  end

  def filter_by_price_range
    return if params[:price_range].blank?

    case params[:price_range]
    when "below_50"
      @rooms = @rooms.joins(:room_type).where("room_types.price < ?", 50)
    when "50_99"
      @rooms = @rooms.joins(:room_type).where(
        "room_types.price BETWEEN ? AND ?", 50, 99
      )
    when "100_200"
      @rooms = @rooms.joins(:room_type).where(
        "room_types.price BETWEEN ? AND ?", 100, 200
      )
    when "above_200"
      @rooms = @rooms.joins(:room_type).where("room_types.price > ?", 200)
    end
  end

  def sort_rooms
    case params[:sort_by]
    when "price_asc"
      @rooms = @rooms.sort_by_price_asc
    when "price_desc"
      @rooms = @rooms.sort_by_price_desc
    when "rating_desc"
      @rooms = @rooms.sort_by_rating_desc
    end
  end

  def set_current_booking
    return unless logged_in?

    @current_booking = current_user.bookings.find_or_create_by(status: :draft)
  end
end
