# frozen_string_literal: true

module TravelManager
  # Transforms Trips into text.
  class TextFormatter
    class << self
      # Formats an array of Trips into text.
      #
      # @param trips [Array<Trip>] array of trips to format.
      # @return [Array, nil] array of arrays with every trip formatted as text,
      # or nil if the trip array is nil or empty.
      def trips_to_text(trips)
        return if trips.nil? || trips.empty?

        text_trips = trips.filter_map { |trip| trip_to_text(trip) }
        return if text_trips.empty?

        text_trips
      end

      private

      # Formats a single Trip into text.
      #
      # @param trip [Trip] the trip to format.
      # @return [Array, nil] string for every segment, plus the header TRIP TO,
      # or nil if the trip is nil or empty.
      def trip_to_text(trip)
        return if trip.nil? || trip.sorted_segments.empty?

        segments_text = trip.sorted_segments.filter_map { |segment| segment_to_text(segment) }
        return if segments_text.empty?

        segments_text.unshift("TRIP to #{trip.destination}")
      end

      # Formats a single Segment into text.
      #
      # @param segment [Segment] the segment to format.
      # @return [String, nil] formatted text, or nil if the segment is nil.
      def segment_to_text(segment)
        return if segment.nil?

        method_name = "#{segment.type.downcase}_to_text"
        return unless supported_type?(segment, method_name)

        send(method_name, segment)
      end

      def supported_type?(segment, method_name)
        return true if respond_to?(method_name, true)

        TravelManager.logger&.warn "Parsed type '#{segment.type}' is not a known Segment type " \
                                   'and cannot be formatted to text. ' \
                                   "Ignoring segment '#{segment.type} #{segment.from} -> #{segment.to}'"
        false
      end

      # Formats a Segment into the hotel text.
      #
      # @param segment [Segment] the segment to format.
      # @return [String, nil] hotel text, or nil if the segment is nil.
      def hotel_to_text(segment)
        return if segment.nil?

        "#{SegmentType::HOTEL} at #{segment.from} on " \
          "#{TimeUtils.date(segment.datetime_from)} to #{TimeUtils.date(segment.datetime_to)}"
      end

      # Formats a Segment into the flight travel text.
      #
      # @param segment [Segment] the segment to format.
      # @return [String, nil] flight travel text, or nil if the segment is nil.
      def flight_to_text(segment)
        return if segment.nil?

        "#{SegmentType::FLIGHT} #{travel_to_text(segment)}"
      end

      # Formats a Segment into the train travel text.
      #
      # @param segment [Segment] the segment to format.
      # @return [String, nil] train travel text, or nil if the segment is nil.
      def train_to_text(segment)
        return if segment.nil?

        "#{SegmentType::TRAIN} #{travel_to_text(segment)}"
      end

      # Formats a Segment into the generic travel text.
      #
      # @param segment [Segment] the segment to format.
      # @return [String, nil] generic travel text, or nil if the segment is nil.
      def travel_to_text(segment)
        return if segment.nil?

        "from #{segment.from} to #{segment.to} at " \
          "#{TimeUtils.datetime(segment.datetime_from)} to #{TimeUtils.time(segment.datetime_to)}"
      end
    end
  end
end
