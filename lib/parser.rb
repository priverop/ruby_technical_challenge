# frozen_string_literal: true

require_relative 'segment'
require_relative 'time_utils'

# Transforms file text into Ruby objects (Segments)
class Parser
  TEXT_PATTERNS = {
    reservation_pattern: 'RESERVATION',
    generic_segment_pattern: /^SEGMENT:\s+(\w+)/,
    trip_segment_pattern: /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+->\s+(\w+)\s+(\d{2}:\d{2})$/, # rubocop:disable Layout/LineLength
    hotel_segment_pattern: /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+->\s+(\d{4}-\d{2}-\d{2})$/
  }.freeze

  class << self
    # Creates an array of Segments from the reservations text of the user.
    #
    # @param reservations [String] input reservation text.
    # @return [Array] parsed Segments.
    def parse(reservations)
      return [] if reservations.nil?

      segments = []

      reservations.split("\n").each do |line|
        next if line == TEXT_PATTERNS[:reservation_pattern]

        parsed_segment = segment(line)
        segments.push(parsed_segment) if parsed_segment
      end
      segments
    end

    private

    # Creates a Segment from Segment text line (Hotel/Flight/Train).
    #
    # @param line [String] SEGMENT: text line.
    # @raise [SegmentTypeNotCompatibleError] if the Segment.Type is not supported.
    # @return [Segment] segment of the right type.
    def segment(line)
      pattern = TEXT_PATTERNS[:generic_segment_pattern]
      matcher = line.match(pattern)

      return unless matcher

      type = matcher.captures.first
      method_name = "#{type.downcase}_segment"

      unless respond_to?(method_name, true)
        raise TravelManager::SegmentTypeNotCompatibleError, "Unknown segment type: #{type}"
      end

      send(method_name, line)
    end

    # Creates a Segment from a Flight text line.
    #
    # @param trip_line [String] flight text line.
    # @return [Segment]
    def flight_segment(trip_line)
      trip_segment(trip_line)
    end

    # Creates a Segment from a Train text line.
    #
    # @param trip_line [String] train text line.
    # @return [Segment]
    def train_segment(trip_line)
      trip_segment(trip_line)
    end

    # Creates a Segment from a Flight/Train Segment text line.
    #
    # @param trip_line [String] text line of type Flight/Train.
    # @return [Segment]
    def trip_segment(trip_line)
      pattern = TEXT_PATTERNS[:trip_segment_pattern]
      matcher = trip_line.match(pattern)

      return unless matcher

      type, from, date_from, time_from, to, time_to = matcher.captures
      Segment.new(
        type: type, from: from, to: to,
        datetime_from: TimeUtils.to_time(date_from, time_from),
        datetime_to: TimeUtils.arrival_time(date_from, time_from, time_to)
      )
    end

    # Creates a Segment from a Hotel Segment text line.
    #
    # @param hotel_line [String] text line of type Hotel.
    # @return [Segment]
    def hotel_segment(hotel_line)
      pattern = TEXT_PATTERNS[:hotel_segment_pattern]
      matcher = hotel_line.match(pattern)

      return unless matcher

      type, from, date_from, date_to = matcher.captures
      Segment.new(
        type: type, from: from, to: from,
        datetime_from: TimeUtils.to_time(date_from, nil),
        datetime_to: TimeUtils.to_time(date_to, nil)
      )
    end
  end
end
