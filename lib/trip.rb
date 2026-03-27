# frozen_string_literal: true

# This class represents a block of sorted segments
class Trip
  attr_reader :destination, :sorted_segments

  def initialize(destination, sorted_segments)
    @destination = destination
    @sorted_segments = sorted_segments
  end
end
