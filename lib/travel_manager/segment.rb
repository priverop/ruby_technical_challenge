# frozen_string_literal: true

require_relative 'segment_type'

module TravelManager
  # Trips are composed by segments.
  # A segment can be a train/flight trip, or a hotel reservation.
  class Segment
    attr_reader :type, :from, :to, :datetime_from, :datetime_to
    attr_accessor :is_connection

    # Creates a new instance of Segment object.
    #
    # @param type [String] type of the Segment.
    # @param from [String] location origin of the Segment.
    # @param to [String] location destination of the Segment.
    # @param datetime_from [Time] when the Segment starts.
    # @param datetime_to [Time] when the Segment ends.
    # @return [Segment] new instance of the object.
    def initialize(type:, from:, to:, datetime_from:, datetime_to:)
      @type = type
      @from = from
      @to = to
      @datetime_from = datetime_from
      @datetime_to = datetime_to
      @is_connection = nil
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
  end
end
