# frozen_string_literal: true

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

  def ==(other)
    return false unless other.is_a?(Trip)

    destination == other.destination &&
      sorted_segments.size == other.sorted_segments.size &&
      sorted_segments.map(&:attributes) == other.sorted_segments.map(&:attributes)
  end
end
