# frozen_string_literal: true

# This class represents a block of sorted segments
class Trip
  attr_reader :destiny, :sorted_segments

  def initialize(destiny, sorted_segments)
    @destiny = destiny
    @sorted_segments = sorted_segments
  end
end
