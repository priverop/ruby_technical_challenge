# frozen_string_literal: true

# This class represents a block of sorted segments
class Trip
  attr_accessor :destiny, :sorted_segments

  def initialize(destiny, sorted_segments)
    self.destiny = destiny
    self.sorted_segments = sorted_segments
  end
end
