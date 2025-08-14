class Request < ApplicationRecord
  has_many :review, dependent: :destroy
  has_many :room_availability_requests, dependent: :destroy
  has_many :room_availabilities, through: :room_availability_requests

  belongs_to :booking
  belongs_to :room

  validates :check_in, presence: true
  validates :check_out, presence: true

  enum status: {
    draft: 0,
    pending: 1,
    confirmed: 2,
    declined: 3,
    cancelled: 4,
    checked_in: 5,
    checked_out: 6
  }, _prefix: true

  def calculate_price
    return nil unless check_in && check_out && room.present?

    if check_in == check_out
      availabilities = room.room_availabilities
                           .where(available_date: check_in)
    else
      availabilities = room.room_availabilities
                           .where(available_date: check_in..check_out)
    end

    return nil if availabilities.empty?

    availabilities.sum(:price)
  end
end
