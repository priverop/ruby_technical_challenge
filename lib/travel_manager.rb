# frozen_string_literal: true

require_relative 'file_reader'
require_relative 'parser'
require_relative 'trip_builder'
require_relative 'text_formatter'

## Main module entry-point - Main controller
# This library transforms the reservations into itineraries
module TravelManager
  class TravelManagerError < StandardError; end
  class FileNotFoundError < TravelManagerError; end
  class FileEmptyError < TravelManagerError; end
  class ArgumentError < TravelManagerError; end
  class SegmentTypeNotCompatibleError < TravelManagerError; end

  class << self
    # Transform the user reservations .txt into a sorted itinerary.
    #
    # @param input_file [String] path of the reservations .txt.
    # @param based [String] starting location of the user.
    # @return [String] sorted itinerary.
    def itinerary(input_file, based)
      validate_based!(based)

      input_reservations = FileReader.read(input_file)

      unsorted_segments = Parser.parse(input_reservations)

      if unsorted_segments.empty?
        raise TravelManager::TravelManagerError, 'there was an error parsing the reservations, please review the input file'
      end

      sorted_trips = TripBuilder.build(unsorted_segments, based)

      if sorted_trips.nil? || sorted_trips.empty?
        raise TravelManager::TravelManagerError, 'there was an error building the trips, please review the input file'
      end

      sorted_trip_texts = TextFormatter.trips_to_text(sorted_trips)

      if sorted_trip_texts.nil? || sorted_trip_texts.empty?
        raise TravelManager::TravelManagerError, 'there was an error formatting the trips, please review the input file'
      end

      build_itinerary(sorted_trip_texts)
    end

    private

    # Composes the itinerary string merging the trip texts.
    #
    # @param sorted_trips [Array] array of trips.
    # @return [String] complete itinerary text.
    def build_itinerary(sorted_trips)
      itinerary = ''

      sorted_trips.each do |trip|
        itinerary += trip.join("\n")
        itinerary += "\n\n"
      end

      itinerary
    end

    # Validates the based param.
    #
    # @param based [STRING] user location.
    # @raise ArgumentError if is not a string, not 3 characters long or not uppercase.
    # @return [void, nil] nil if validation is correct.
    def validate_based!(based)
      return unless !based.is_a?(String) || based.length != 3 || based != based.upcase

      raise TravelManager::ArgumentError, "#{based} should be a three-letter uppercase string"
    end
  end
end
