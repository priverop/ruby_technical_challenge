# frozen_string_literal: true

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

  # Gets the destiny of the trip looking at the hotel or the last place before going home
  # Check the documentation for more info about this method
  # Returns a String
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

      # Two flights are a connection if there is less than 24 hours difference
      if next_segment.flight? &&
         previous.flight? &&
         TimeUtils.hours_difference(next_segment.datetime_from, previous.datetime_to) < 24
        previous.is_connection = true
      end
      previous = next_segment
    end
    sorted
  end

  # Gets the next linked segment of the "previous" segment
  def self.find_link(segments, previous)
    segments.find { |segment| segment.from == previous.to && TimeUtils.same_dates?(segment.datetime_from, previous.datetime_to) }
  end
end
