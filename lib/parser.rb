# frozen_string_literal: true

require_relative 'segment'

# Transforms file text into Ruby objects (Segments)
class Parser

  # Creates an array of Segments from the reservations full text of the user
  #
  # @param reservations [String] input reservation text
  # @return [Array] parsed Segments
  def self.parse(reservations)
    return [] if reservations.nil?

    segments = []

    reservations.split("\n").each do |line|
      next if line == 'RESERVATION'

      parsed_segment = segment(line)
      segments.push(parsed_segment) if parsed_segment
    end
    segments
  end

  # Creates a Segment from Segment text line (Hotel/Flight/Train)
  #
  # @param [String] SEGMENT: text line
  # @return [Segment] of the right type
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

  # Creates a Segment from a Flight/Train Segment text line
  #
  # @param [String] text line of type Flight/Train
  # @return [Segment]
  def self.trip_segment(trip_line)
    pattern = /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+->\s+(\w+)\s+(\d{2}:\d{2})$/
    matcher = trip_line.match(pattern)

    return unless matcher

    type, from, date_from, time_from, to, time_to = matcher.captures
    Segment.new(type, from, to, date_from, date_from, time_from, time_to)
  end

  # Creates a Segment from a Hotel Segment text line
  #
  # @param [String] text line of type Hotel
  # @return [Segment]
  def self.hotel_segment(hotel_line)
    pattern = /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+->\s+(\d{4}-\d{2}-\d{2})$/
    matcher = hotel_line.match(pattern)

    return unless matcher

    type, from, date_from, date_to = matcher.captures
    Segment.new(type, from, from, date_from, date_to, nil, nil)
  end
end
