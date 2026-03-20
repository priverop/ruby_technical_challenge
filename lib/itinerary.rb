# frozen_string_literal: true

# Array to Text
class Itinerary
  def self.generate(trips)
    trips.map do |trip|
      trip_to_text(trip)
    end
  end

  def self.trip_to_text(trip)
    segments_text = trip.sorted_segments.map do |segment|
      segment_to_text(segment)
    end

    segments_text.unshift("TRIP to #{trip.destiny}")
  end

  def self.segment_to_text(segment)
    send "#{segment.type.downcase}_to_text", segment
  end

  def self.hotel_to_text(segment)
    "Hotel at #{segment.from} on #{segment.date_from} to #{segment.date_to}"
  end

  def self.flight_to_text(segment)
    "Flight #{travel_to_text(segment)}"
  end

  def self.train_to_text(segment)
    "Train #{travel_to_text(segment)}"
  end

  def self.travel_to_text(segment)
    "from #{segment.from} to #{segment.to} at #{segment.date_from} #{segment.time_from} to #{segment.time_to}"
  end
end
