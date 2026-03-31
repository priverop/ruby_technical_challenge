# frozen_string_literal: true

require_relative 'travel_manager/itinerary'

# Main library entry-point.
module TravelManager
  class TravelManagerError < StandardError; end
  class FileNotFoundError < TravelManagerError; end
  class FileEmptyError < TravelManagerError; end
  class FileExtensionError < TravelManagerError; end
  class ArgumentError < TravelManagerError; end
  class SegmentTypeNotCompatibleError < TravelManagerError; end

  def self.itinerary(file:, based:)
    Itinerary.generate(file, based)
  end
end
