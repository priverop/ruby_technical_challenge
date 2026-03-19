# frozen_string_literal: true

# Trips are composed by segments.
# A segment can be a train/flight trip, or a hotel reservation.
class Segment
  attr_accessor :type, :from, :to, :date_from, :date_to, :time_from, :time_to

  def initialize(type, from, to, date_from, date_to, time_from, time_to)
    self.type = type
    self.from = from
    self.to = to
    self.date_from = date_from
    self.date_to = date_to
    self.time_from = time_from
    self.time_to = time_to
  end
end
