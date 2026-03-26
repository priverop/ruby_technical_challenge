# frozen_string_literal: true

require_relative 'time_utils'

# Trips are composed by segments.
# A segment can be a train/flight trip, or a hotel reservation.
class Segment
  attr_accessor :type, :from, :to, :datetime_from, :datetime_to, :is_connection

  def initialize(type, from, to, datetime_from, datetime_to, time_from, time_to) # rubocop:disable Metrics/ParameterLists
    self.type = type
    self.from = from
    self.to = to
    self.datetime_from = TimeUtils.to_time(datetime_from, time_from)
    self.datetime_to = TimeUtils.to_time(datetime_to, time_to)
    self.is_connection = false
  end

  def attributes
    {
      type: type,
      from: from,
      to: to,
      datetime_from: datetime_from,
      datetime_to: datetime_to,
      is_connection: is_connection
    }
  end

  def flight?
    type == 'Flight'
  end

  def connection?
    is_connection
  end

  # To compare segments when testing
  def ==(other)
    return false unless other.is_a?(Segment)

    attributes == other.attributes
  end
end
