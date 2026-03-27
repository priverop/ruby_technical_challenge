# frozen_string_literal: true

require_relative 'segment_type'

# Trips are composed by segments.
# A segment can be a train/flight trip, or a hotel reservation.
class Segment
  include SegmentType

  attr_reader :type, :from, :to, :datetime_from, :datetime_to
  attr_accessor :is_connection

  def initialize(type:, from:, to:, datetime_from:, datetime_to:)
    @type = type
    @from = from
    @to = to
    @datetime_from = datetime_from
    @datetime_to = datetime_to
    @is_connection = false
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
    type == SegmentType::FLIGHT
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
