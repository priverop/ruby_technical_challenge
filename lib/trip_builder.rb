# frozen_string_literal: true

require 'debug'
require_relative 'segment'
require_relative 'time_utils'
require_relative 'trip'

# Links segments to each other to make itineraries.
class TripBuilder
  CONNECTION_HOURS_LIMIT = 24

  class << self
    # Build all the Trips for the itinerary.
    #
    # @param unsorted_segments [Array] unsorted segments to pull from.
    # @param based [String] starting location of the user.
    #
    # @return [Array] sorted Trips with sorted segments and destination.
    #
    def build(unsorted_segments, based)
      # Gets all the segments that start in the based location
      based_segments = unsorted_segments.select { |segment| segment.from == based }
                                        .sort_by(&:datetime_from)

      return if based_segments.empty?

      based_segments.map do |based_start|
        sorted_segments = sorted_segments(based_start, unsorted_segments)
        destination = find_trip_destination(sorted_segments)
        Trip.new(destination, sorted_segments)
      end
    end

    private

    # Gets the destination of the trip, ignoring connection flights.
    #
    # @param sorted_segments [Array] sorted trip segments.
    # @return [String] the trip destination.
    def find_trip_destination(sorted_segments)
      sorted_segments.find { |segment| !segment.connection? }.to
    end

    # Gets all the linked segments starting from the "previous" segment.
    #
    # @param previous [Segment] based segment, where the trip starts.
    # @param unsorted_segments [Array] unsorted segments.
    #
    # @return [Array] sorted segments or empty if links not found.
    #
    def sorted_segments(previous, unsorted_segments)
      sorted = []
      loop do
        sorted.push(previous)
        next_segment = find_link(unsorted_segments - sorted, previous)
        break if next_segment.nil? # no more segments in the trip

        previous.is_connection = check_connection?(previous, next_segment)
        previous = next_segment
      end
      sorted
    end

    # Gets the next linked segment of the "previous" segment.
    #
    # @param unsorted_segments [Array] unsorted segments to look for the link.
    # @param previous [Segment] "before" segment.
    # @return [Segment] following segment to the "previous" param.
    def find_link(unsorted_segments, previous)
      unsorted_segments.find do |segment|
        next unless segment.from == previous.to

        segment.datetime_to >= previous.datetime_from &&
          TimeUtils.hours_difference(segment.datetime_from, previous.datetime_to) <= CONNECTION_HOURS_LIMIT
      end
    end

    # Checks if two segments are connection flights.
    # Two flights are a connection if there is less than 24 hours difference.
    #
    # @param previous [Segment] starting flight.
    # @param next_segment [Segment] following flight.
    # @return [Boolean] true if conditions are met.
    def check_connection?(previous, next_segment)
      if next_segment.flight? && previous.flight? &&
         next_segment != previous &&
         TimeUtils.hours_difference(next_segment.datetime_from, previous.datetime_to) <= CONNECTION_HOURS_LIMIT
        return true
      end

      false
    end
  end
end
