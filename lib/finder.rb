# frozen_string_literal: true

require_relative 'segment'
require_relative 'time_utils'
require_relative 'trip'

# Links segments to each other to make itineraries
class Finder
  def self.find(segments, based)
    # Gets all the segments that start in the based location
    based_segments = segments.select { |segment| segment.from == based }
                             .sort_by(&:datetime_from)

    return if based_segments.empty?

    based_segments.map do |based_start|
      sorted_segments = sorted_segments(based_start, segments)
      destiny = find_trip_destiny(sorted_segments)
      Trip.new(destiny, sorted_segments)
    end
  end

  # Gets the destiny of the trip, ignoring connection flights.
  #
  # @param sorted_segments [Array] sorted trip segments.
  # @return [String] the trip destination.
  def self.find_trip_destiny(sorted_segments)
    sorted_segments.find { |segment| !segment.connection? }.to
  end

  # Gets all the linked segments starting from the "previous" segment (which is the based_segment)
  def self.sorted_segments(previous, segments)
    sorted = []
    loop do
      sorted.push(previous)
      next_segment = find_link(segments, previous)
      break if next_segment.nil? # no more segments in the trip

      check_connection(previous, next_segment)
      previous = next_segment
    end
    sorted
  end

  # Gets the next linked segment of the "previous" segment
  # TODO: this returns the first one, what if there are multiple in the same day?
  def self.find_link(segments, previous)
    segments.find do |segment|
      segment.from == previous.to &&
        (
          # Hotel times are 00:00, which messes up with the hour difference
          TimeUtils.same_dates?(segment.datetime_from, previous.datetime_to) ||
          (
            TimeUtils.hours_difference(segment.datetime_from, previous.datetime_to).positive? &&
            TimeUtils.hours_difference(segment.datetime_from, previous.datetime_to) < 24
          )
        )
    end
  end

  # Sets the previous segment as is_connection, if condition is met.
  # Two flights are a connection if there is less than 24 hours difference.
  #
  # @param previous [Segment] starting flight.
  # @param next_segment [Segment] following flight.
  # @return [Boolean] true if conditions are met
  def self.check_connection(previous, next_segment) # rubocop:disable Naming/PredicateMethod
    if next_segment.flight? && previous.flight? &&
       next_segment != previous &&
       TimeUtils.hours_difference(next_segment.datetime_from, previous.datetime_to) < 24
      previous.is_connection = true
      return true
    end
    false
  end
end
