# frozen_string_literal: true

require_relative 'segment_type'

# Trips are composed by segments.
# A segment can be a train/flight trip, or a hotel reservation.
class Segment
  include SegmentType

  attr_reader :type, :from, :to, :datetime_from, :datetime_to
  attr_accessor :is_connection

  # Creates a new instance of Segment object.
  #
  # @param type [String] type of the Segment.
  # @param from [String] location origin of the Segment.
  # @param to [String] location destination of the Segment.
  # @param datetime_from [Time] when the Segment starts.
  # @param datetime_to [Time] when the Segment ends.
  # @return [void]
  def initialize(type:, from:, to:, datetime_from:, datetime_to:)
    @type = type
    @from = from
    @to = to
    @datetime_from = datetime_from
    @datetime_to = datetime_to
    @is_connection = false
  end

  # Attributes of the Segment. Useful for testing.
  #
  # @return [Hash] attributes of the Segment.
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

  # Checks if the segment is a Flight.
  #
  # @return [Boolean] true if segment has Flight type.
  def flight?
    type == SegmentType::FLIGHT
  end

  # Checks if the segment is a connection trip.
  #
  # @return [Boolean] value of is_connection.
  def connection?
    is_connection
  end

  # To compare segments when testing.
  #
  # @param other [Segment] the other Segment to compare with.
  # @return [Boolean] true if same attributes.
  def ==(other)
    return false unless other.is_a?(Segment)

    attributes == other.attributes
  end
end
