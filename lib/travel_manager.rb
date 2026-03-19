# frozen_string_literal: true

require_relative 'client'
require_relative 'parser'

## Main module entry-point - Main controller
# This library transforms the reservations into itineraries
module TravelManager
  class FileNotFoundError < StandardError; end

  def self.itinerary(input_file)
    input_reservations = Client.read(input_file)
    clean_reservations = Parser.parse(input_reservations)
  end
end