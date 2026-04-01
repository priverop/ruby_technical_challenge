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
      # Parses reservation text into Segment objects.
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

      # Parses a SEGMENT line into a Segment object.
      #
      # @param line [String] SEGMENT: text line.
      # @return [Segment, nil] segment of the right type, or nil if the segment type is not supported.
      def segment(line)
        matcher = match_pattern(
          line,
          :generic_segment_pattern,
          :segment_not_found
        )
        return unless matcher

        type = matcher.captures.first
        method_name = "#{type.downcase}_segment"
        return unless supported_type?(type, method_name, line)

        send(method_name, line)
      end

      # Parses a Flight segment.
      #
      # @param trip_line [String] flight text line.
      # @return [Segment]
      def flight_segment(trip_line)
        trip_segment(trip_line)
      end

      # Parses a Train segment.
      #
      # @param trip_line [String] train text line.
      # @return [Segment]
      def train_segment(trip_line)
        trip_segment(trip_line)
      end

      # Parses a Flight/Train segment.
      #
      # @param trip_line [String] text line of type Flight/Train.
      # @return [Segment, nil] new Segment, or nil if the parsed from and to are not a valid IATA code.
      def trip_segment(trip_line)
        matcher = match_pattern(
          trip_line,
          :trip_segment_pattern,
          :invalid_line_format,
          { type: 'Flight/Train', expected: 'SEGMENT: Type FROM DATE TIME -> TO TIME' }
        )
        return unless matcher

        type, from, date_from, time_from, to, time_to = matcher.captures
        return unless valid_iata?(from) && valid_iata?(to) && from != to

        build_segment(
          type: type,
          from: from,
          to: to,
          datetime_from: TimeUtils.to_time(date_from, time_from),
          datetime_to: TimeUtils.arrival_time(date_from, time_from, time_to)
        )
      end

      # Parses a Hotel segment.
      #
      # @param hotel_line [String] text line of type Hotel.
      # @return [Segment, nil] new Segment, or nil if the parsed from is not a valid IATA code.
      def hotel_segment(hotel_line)
        matcher = match_pattern(
          hotel_line,
          :hotel_segment_pattern,
          :invalid_line_format,
          { expected: 'SEGMENT: Hotel FROM DEPARTURE_DATE -> TO', type: 'Hotel' }
        )
        return unless matcher

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

      # Matches a line against a pattern and logs if it fails.
      #
      # @param line [String] string to find matches. The line we are parsing.
      # @param pattern_key [Symbol] key of the patern constants.
      # @param error_key [Symbol] key of the error templates.
      # @param error_variables [Hash] variables for the error template.
      # @return [MatchData, nil] matched data or nil if not match.
      def match_pattern(line, pattern_key, error_key, error_variables = {})
        pattern = TEXT_PATTERNS[pattern_key]
        matcher = line.match(pattern)
        return matcher if matcher

        TravelManager.logger&.warn(
          format(ERROR_MESSAGES[error_key], error_variables.merge(line:))
        )

        nil
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

      # Checks if a segment type is supported.
      #
      # @param type [String] segment type.
      # @param method_name [String] name of the specific parser.
      # @param line [String] line of the reservations that we are trying to parse.
      # @return [Boolean] true if there is a method to parse this segment type.
      def supported_type?(type, method_name, line)
        return true if respond_to?(method_name, true)

        TravelManager.logger&.warn(format(ERROR_MESSAGES[:unknown_type], type:, line:))
        false
      end

      # Builds a Segment object.
      #
      # @param type [String]
      # @param from [String]
      # @param to [String]
      # @param datetime_from [Time]
      # @param datetime_to [Time]
      # @return [Segment]
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
