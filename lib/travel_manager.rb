# frozen_string_literal: true

require_relative 'travel_manager/itinerary'
require 'logger'

# Main library entry-point.
module TravelManager
  class TravelManagerError < StandardError; end
  class FileNotFoundError < TravelManagerError; end
  class FileEmptyError < TravelManagerError; end
  class FileReadError < TravelManagerError; end
  class BasedArgumentError < TravelManagerError; end

  # Public facade for Itinerary.
  #
  # @param file [String] input file of the user.
  # @param based [String] based location of the user.
  #
  # @return [String] sorted itinerary.
  #
  def self.itinerary(file:, based:)
    Itinerary.generate(file, based)
  end

  # Getter for the logger.
  #
  # @return [Logger]
  #
  def self.logger
    @logger
  end

  # Setter for the logger.
  #
  # @param [Logger] logger instance.
  #
  # @return [Logger]
  #
  def self.logger=(logger)
    @logger = logger
  end
end
