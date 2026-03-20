# frozen_string_literal: true

# Links segments to each other to make itineraries
class Finder
  def self.find(segments, based)
    # Gets all the segments that start in the based location
    based_segments = segments.select { |segment| segment.from == based }
                             .sort_by(&:date_from)

    based_segments.map do |based_start|
      linked_segments(based_start, segments)
    end
  end

  # Gets all the linked segments starting from the "previous" segment (which is the based_segment)
  def self.linked_segments(previous, segments)
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
    segments.select { |segment| segment.from == previous.to && segment.date_from == previous.date_to }.first
  end
end
