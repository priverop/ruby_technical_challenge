# frozen_string_literal: true

require_relative 'client'
require_relative 'parser'
require_relative 'trip_builder'
require_relative 'text_formatter'

## Main module entry-point - Main controller
# This library transforms the reservations into itineraries
module TravelManager
  class FileNotFoundError < StandardError; end
  class ArgumentError < StandardError; end
  class SegmentTypeNotCompatibleError < StandardError; end

  def self.itinerary(input_file, based)
    validate_based!(based)

    input_reservations = Client.read(input_file)
    unsorted_segments = Parser.parse(input_reservations)
    sorted_trips = TripBuilder.build(unsorted_segments, based)

    return 'ERROR!' if sorted_trips.nil? # TODO: better error

    sorted_trip_texts = TextFormatter.trips_to_text(sorted_trips)

    print_itinerary(sorted_trip_texts)
  end

  def self.print_itinerary(sorted_trips)
    itinerary = ''

    sorted_trips.each do |trip|
      itinerary += trip.join("\n")
      itinerary += "\n\n"
    end

    itinerary
  end

  def self.validate_based!(based)
    return unless !based.is_a?(String) || based.length != 3 || based != based.upcase

    raise TravelManager::ArgumentError, "#{based} should be a three-letter uppercase string"
  end
end
