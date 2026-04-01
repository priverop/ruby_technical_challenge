# frozen_string_literal: true

require_relative 'segment'
require_relative 'time_utils'

module TravelManager
  # Transforms file text into Ruby objects (Segments)
  class Parser
    TEXT_PATTERNS = {
      reservation_pattern: 'RESERVATION',
      generic_segment_pattern: /^SEGMENT:\s+(\w+)/,
      trip_segment_pattern: /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+->\s+(\w+)\s+(\d{2}:\d{2})$/, # rubocop:disable Layout/LineLength
      hotel_segment_pattern: /^SEGMENT:\s+(\w+)\s+(\w+)\s+(\d{4}-\d{2}-\d{2})\s+->\s+(\d{4}-\d{2}-\d{2})$/
    }.freeze

    ERROR_MESSAGES = {
      segment_not_found: 'SEGMENT pattern not found, ignoring line: %<line>s.',
      unknown_type: "Parsed type '%<type>s' is not a known Segment type. Ignoring line '%<line>s'.",
      invalid_line_format: "Invalid '%<type>s' format, ignoring line. Expected %<expected>s, got %<line>s.",
      invalid_iata: "Parsed location '%<iata>s' is not a valid IATA code: it should be three-letter uppercase."
    }.freeze

    class << self
      # Creates an array of Segments from the reservations text of the user.
      #
      # @param reservations [String] input reservation text.
      # @return [Array<Segment>] parsed Segments.
      def parse(reservations)
        return [] if reservations.nil?

        segments = []

        # remove Windows OS end lines before splitting
        reservations.gsub("\r\n", "\n").split("\n").each do |line|
          next if line == TEXT_PATTERNS[:reservation_pattern] || line.empty?

          parsed_segment = segment(line.strip)
          segments.push(parsed_segment) if parsed_segment
        end
        segments
      end

      private

      # Creates a Segment from Segment text line (Hotel/Flight/Train).
      #
      # @param line [String] SEGMENT: text line.
      # @return [Segment, nil] segment of the right type, or nil if the segment type is not supported.
      def segment(line)
        pattern = TEXT_PATTERNS[:generic_segment_pattern]
        matcher = line.match(pattern)

        if matcher.nil?
          TravelManager.logger&.warn(format(ERROR_MESSAGES[:segment_not_found], line:))
          return
        end

        type = matcher.captures.first
        method_name = "#{type.downcase}_segment"
        return unless supported_type?(type, method_name, line)

        send(method_name, line)
      end

      def supported_type?(type, method_name, line)
        return true if respond_to?(method_name, true)

        TravelManager.logger&.warn(format(ERROR_MESSAGES[:unknown_type], type:, line:))
        false
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
      # @return [Segment, nil] new Segment, or nil if the parsed from and to are not a valid IATA code.
      def trip_segment(trip_line)
        pattern = TEXT_PATTERNS[:trip_segment_pattern]
        matcher = trip_line.match(pattern)

        if matcher.nil?
          TravelManager.logger&.warn(format(ERROR_MESSAGES[:invalid_line_format],
                                            type: 'Flight/Train',
                                            expected: 'SEGMENT: Type FROM DEPARTURE_DATE DEPARTURE_TIME ' \
                                                      '-> TO ARRIVAL_TIME',
                                            line: trip_line))
          return
        end

        type, from, date_from, time_from, to, time_to = matcher.captures
        return unless valid_iata?(from) && valid_iata?(to)

        build_segment(
          type: type,
          from: from,
          to: to,
          datetime_from: TimeUtils.to_time(date_from, time_from),
          datetime_to: TimeUtils.arrival_time(date_from, time_from, time_to)
        )
      end

      # Creates a Segment from a Hotel Segment text line.
      #
      # @param hotel_line [String] text line of type Hotel.
      # @return [Segment, nil] new Segment, or nil if the parsed from is not a valid IATA code.
      def hotel_segment(hotel_line)
        pattern = TEXT_PATTERNS[:hotel_segment_pattern]
        matcher = hotel_line.match(pattern)

        if matcher.nil?
          TravelManager.logger&.warn(format(ERROR_MESSAGES[:invalid_line_format],
                                            type: 'Hotel',
                                            expected: 'SEGMENT: Hotel FROM DEPARTURE_DATE -> TO',
                                            line: hotel_line))
          return
        end

        type, from, date_from, date_to = matcher.captures
        return unless valid_iata?(from)

        build_segment(
          type: type,
          from: from,
          to: from,
          datetime_from: TimeUtils.to_time(date_from, nil),
          datetime_to: TimeUtils.to_time(date_to, nil)
        )
      end

      # Checks wether the input location string is a correct IATA code.
      #
      # @param iata [String] input IATA code.
      # @return [Boolean] true if the string is 3 character long and all uppercase.
      def valid_iata?(iata)
        return true unless iata.length != 3 || iata != iata.upcase

        TravelManager.logger&.warn(format(ERROR_MESSAGES[:invalid_iata], iata:))
        false
      end

      def build_segment(type:, from:, to:, datetime_from:, datetime_to:)
        Segment.new(
          type: type, from: from, to: to,
          datetime_from: datetime_from,
          datetime_to: datetime_to
        )
      end
    end
  end
end
