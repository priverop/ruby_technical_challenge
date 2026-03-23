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
      destiny = find_trip_destiny(sorted_segments, based)
      Trip.new(destiny, sorted_segments)
    end
  end

  # Gets the destiny of the trip looking at the hotel or the last place before going home
  # Check the documentation for more info about this method
  # TODO: Encapsulate
  def self.find_trip_destiny(sorted_segments, based)
    last_hotel = sorted_segments.select { |segment| segment.type == 'Hotel' }
                                .max_by(&:datetime_from)

    return last_hotel.to unless last_hotel.nil?

    # If there is no hotel, let's find the last segment before going home
    last_segment_before_home = sorted_segments.select { |segment| segment.to == based }.last

    return last_segment_before_home.from unless last_segment_before_home.nil?

    # If there is no trip back home, let's return the last visited place

    sorted_segments.last.to
  end

  # Gets all the linked segments starting from the "previous" segment (which is the based_segment)
  def self.sorted_segments(previous, segments)
    sorted = []
    loop do
      sorted.push(previous)
      previous = find_link(segments, previous)
      break if previous.nil?
    end
    sorted
  end

  # Gets the next linked segment of the "previous" segment
  def self.find_link(segments, previous)
    segments.select { |segment| segment.from == previous.to && TimeUtils.same_dates?(segment.datetime_from, previous.datetime_to) }.first
  end
end
