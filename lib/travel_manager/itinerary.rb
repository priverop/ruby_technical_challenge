# frozen_string_literal: true

require_relative 'file_reader'
require_relative 'parser'
require_relative 'trip_builder'
require_relative 'text_formatter'

module TravelManager
  # Main controller, transforms user reservations into a itinerary.
  class Itinerary
    class << self
      # Transforms the user reservations .txt into a sorted text itinerary.
      #
      # @param input_file [String] path of the reservations .txt.
      # @param based [String] starting location of the user.
      # @raise [TravelManagerError] if the Parser returns an empty array.
      # @raise [TravelManagerError] if the TripBuilder returns an empty array or nil.
      # @raise [TravelManagerError] if the TextFormatter returns nil.
      # @return [String] sorted itinerary.
      #
      def generate(input_file, based)
        validate_based!(based)

        input_reservations = FileReader.read(input_file)

        segments = parse_segments!(input_reservations, input_file)

        trips = build_trips!(segments, based)

        trip_texts = format_trips!(trips)

        build_itinerary(trip_texts)
      end

      private

      # Composes the itinerary string merging the trip text arrays.
      #
      # @param sorted_trips [Array<Trip>] array of trips.
      # @return [String] complete itinerary text.
      def build_itinerary(sorted_trips)
        sorted_trips.map { |trip| trip.join("\n") }.join("\n\n")
      end

      # Validates the based param.
      #
      # @param based [String] user location.
      # @raise ArgumentError if is not a string, not 3 characters long or not uppercase.
      # @return [void, nil] nil if validation is correct.
      def validate_based!(based)
        return unless !based.is_a?(String) || based.length != 3 || based != based.upcase

        raise TravelManager::ArgumentError, "The based variable (#{based}) should be a three-letter uppercase string."
      end

      # Parses reservations into segments.
      #
      # @param reservations [String] raw reservation text.
      # @param input_file [String] path used only for the error message.
      # @raise [TravelManagerError] if the parser returns an empty array.
      # @return [Array<Segment>]
      def parse_segments!(reservations, input_file)
        segments = Parser.parse(reservations)
        return segments unless segments.empty?

        raise TravelManager::TravelManagerError,
              "#{input_file} could not be parsed. Please review the logs."
      end

      # Builds trips from segments.
      #
      # @param segments [Array<Segment>]
      # @param based [String] user initial location.
      # @raise [TravelManagerError] if no trips are found from the base location.
      # @return [Array<Trip>]
      def build_trips!(segments, based)
        trips = TripBuilder.build(segments, based)
        return trips unless trips.nil? || trips.empty?

        raise TravelManager::TravelManagerError, "No segments from #{based} found."
      end

      # Formats trips into text.
      #
      # @param trips [Array<Trip>]
      # @raise [TravelManagerError] if the formatter returns nil.
      # @return [Array<Array<String>>]
      def format_trips!(trips)
        trip_texts = TextFormatter.trips_to_text(trips)
        return trip_texts unless trip_texts.nil?

        raise TravelManager::TravelManagerError, 'Trips could not be formatted. Please review the logs.'
      end
    end
  end
end
