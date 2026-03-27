# frozen_string_literal: true

# Transforms Trips into text.
class TextFormatter
  # Formats an array of Trips into text.
  #
  # @param trips [Array] array of trips to format.
  # @return [Array, nil] array of arrays with every trip formatted as text,
  # or nil if the trip array is nil or empty.
  def self.trips_to_text(trips)
    return if trips.nil? || trips.empty?

    trips.map do |trip|
      trip_to_text(trip)
    end
  end

  # Formats the entire Trip into text.
  #
  # @param trip [Trip] the trip to format.
  # @return [Array, nil] string for every segment, plus the header TRIP TO,
  # or nil if the trip is nil or empty.
  def self.trip_to_text(trip)
    return if trip.nil? || trip.sorted_segments.empty?

    segments_text = trip.sorted_segments.map do |segment|
      segment_to_text(segment)
    end

    segments_text.unshift("TRIP to #{trip.destination}") unless segments_text.empty?
  end

  # Formats a single Segment into text.
  #
  # @raise [SegmentTypeNotCompatibleError] if the segment type has not a method to_text implemented.
  # @param segment [Segment] the segment to format.
  # @return [String, nil] formatted text, or nil if the segment is nil.
  def self.segment_to_text(segment)
    return if segment.nil?

    method_name = "#{segment.type.downcase}_to_text"

    raise TravelManager::SegmentTypeNotCompatibleError, "Unknown segment type: #{segment.type}" unless respond_to?(method_name)

    send(method_name, segment)
  end

  # Formats a Segment into the hotel text.
  #
  # @param segment [Segment] the segment to format.
  # @return [String, nil] hotel text, or nil if the segment is nil.
  def self.hotel_to_text(segment)
    return if segment.nil?

    "#{SegmentType::HOTEL} at #{segment.from} on #{TimeUtils.date(segment.datetime_from)} to #{TimeUtils.date(segment.datetime_to)}"
  end

  # Formats a Segment into the flight travel text.
  #
  # @param segment [Segment] the segment to format.
  # @return [String, nil] flight travel text, or nil if the segment is nil.
  def self.flight_to_text(segment)
    return if segment.nil?

    "#{SegmentType::FLIGHT} #{travel_to_text(segment)}"
  end

  # Formats a Segment into the train travel text.
  #
  # @param segment [Segment] the segment to format.
  # @return [String, nil] train travel text, or nil if the segment is nil.
  def self.train_to_text(segment)
    return if segment.nil?

    "#{SegmentType::TRAIN} #{travel_to_text(segment)}"
  end

  # Formats a Segment into the generic travel text.
  #
  # @param segment [Segment] the segment to format.
  # @return [String, nil] generic travel text, or nil if the segment is nil.
  def self.travel_to_text(segment)
    return if segment.nil?

    "from #{segment.from} to #{segment.to} at #{TimeUtils.datetime(segment.datetime_from)} to #{TimeUtils.time(segment.datetime_to)}"
  end
end
