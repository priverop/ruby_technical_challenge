# frozen_string_literal: true

require_relative 'client'
require_relative 'parser'
require_relative 'finder'
require_relative 'itinerary'

## Main module entry-point - Main controller
# This library transforms the reservations into itineraries
module TravelManager
  class FileNotFoundError < StandardError; end

  def self.itinerary(input_file, based)
    return 'ERROR' if based.length != 3

    input_reservations = Client.read(input_file)
    segments = Parser.parse(input_reservations)
    trips = Finder.find(segments, based)

    return 'ERROR!' if trips.nil?

    sorted_trips = Itinerary.generate(trips)

    print_itinerary(sorted_trips)
  end

  def self.print_itinerary(sorted_trips)
    itinerary = ''

    sorted_trips.each do |trip|
      itinerary += trip.join("\n")
      itinerary += "\n\n"
    end

    itinerary
  end
end
