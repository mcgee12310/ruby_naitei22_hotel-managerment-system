class Room < ApplicationRecord
  IMAGE_RESIZE_LIMIT = [600, 300].freeze

  belongs_to :room_type

  has_many :room_amenities, dependent: :destroy
  has_many :amenities, through: :room_amenities

  has_many :requests, dependent: :destroy
  has_many :room_availabilities, dependent: :destroy
  has_many :room_availability_requests, through: :room_availabilities
  has_many :reviews, through: :requests

  has_many_attached :images do |attachable|
    attachable.variant :display, resize_to_limit: IMAGE_RESIZE_LIMIT
  end

  enum status: {
    available: 0,
    occupied: 1,
    maintenance: 2
  }, _prefix: true

  scope :sort_by_price_asc, lambda {
    joins(:room_type).order("room_types.price ASC")
  }

  scope :sort_by_price_desc, lambda {
    joins(:room_type).order("room_types.price DESC")
  }

  scope :sort_by_rating_desc, lambda {
    left_joins(requests: :review)
      .group("rooms.id")
      .order(Arel.sql("AVG(reviews.rating) IS NULL, AVG(reviews.rating) DESC"))
  }

  def average_rating
    reviews.average(:rating)&.round(1) || 0
  end

  def number_of_rating
    reviews.count(:id)
  end

  def available_dates
    room_availabilities
      .left_joins(:room_availability_requests)
      .where(room_availability_requests: {id: nil})
      .pluck(:available_date)
  end

  def total_price_for_dates check_in, check_out
    return 0 if check_in.blank? || check_out.blank? || check_in >= check_out

    room_availabilities
      .where(available_date: check_in...check_out)
      .sum(:price)
  end
end
