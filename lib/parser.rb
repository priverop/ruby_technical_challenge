# frozen_string_literal: true

require_relative 'segment'

# Transforms file info into Ruby objects
class Parser
  def self.parse(reservations)
    segments = []

    reservations.split("\n").each do |line|
      next if line == 'RESERVATION'

      parsed_segment = segment(line)
      segments.push(parsed_segment) if parsed_segment
    end
    segments
  end

  def self.segment(line)
    pattern = /^SEGMENT:\s+(\w+)/
    matcher = line.match(pattern)

    return unless matcher # TODO: tiene sentido?

    type = matcher.captures

    if type.include?('Hotel') # TODO: More robust?
      hotel_segment(line)
    else
      trip_segment(line)
    end
  end

  def self.trip_segment(trip_line)
    pattern = /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+->\s+(\w+)\s+(\d{2}:\d{2})$/
    matcher = trip_line.match(pattern)

    return unless matcher

    type, from, date_from, time_from, to, time_to = matcher.captures
    Segment.new(type, from, to, date_from, date_from, time_from, time_to) # TODO: DATE_TO ??? CUIDAO!
  end

  def self.hotel_segment(hotel_line)
    pattern = /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+->\s+(\d{4}-\d{2}-\d{2})$/
    matcher = hotel_line.match(pattern)

    return unless matcher

    type, from, date_from, date_to = matcher.captures
    Segment.new(type, from, from, date_from, date_to, nil, nil) ## TODO: OJO EL FROM DOBLE
  end
end
