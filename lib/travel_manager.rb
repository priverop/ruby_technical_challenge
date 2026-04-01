# frozen_string_literal: true

require_relative 'travel_manager/itinerary'
require 'logger'

# Main library entry-point.
module TravelManager
  class TravelManagerError < StandardError; end
  class FileNotFoundError < TravelManagerError; end
  class FileEmptyError < TravelManagerError; end
  class FileReadError < TravelManagerError; end
  class ArgumentError < TravelManagerError; end

  # Public facade for Itinerary.
  #
  # @param file [String] input file of the user.
  # @param based [String] based location of the user.
  #
  # @return [Strimg] sorted itinerary.
  #
  def self.itinerary(file:, based:)
    Itinerary.generate(file, based)
  end

  # Getter for the logger.
  #
  # @return [void]
  #
  def self.logger
    @logger
  end

  # Setter for the logger.
  #
  # @param [Logger] logger instance.
  #
  # @return [void]
  #
  def self.logger=(logger)
    @logger = logger
  end
end
