# frozen_string_literal: true

module TravelManager
  # This class represents a single travel itinerary (destination, and the sorted segments).
  class Trip
    attr_reader :destination, :sorted_segments

    # Creates a new instance of Trip.
    #
    # @param destination [String] where the user is headed.
    # @param sorted_segments [Array] linked segments.
    #
    def initialize(destination, sorted_segments)
      @destination = destination
      @sorted_segments = sorted_segments
    end
  end
end
