# frozen_string_literal: true

require_relative 'segment'

# Transforms file info into Ruby objects
class Parser
  def self.parse(reservations)
    segments = []

    reservations.split("\n").each do |line|
      next if line == 'RESERVATION'

      segments.push(segment(line))
    end
    segments
  end

  def self.segment(line)
    words = line.split
    # los dos puntos van fuera
    # opcionales:
    #   date_from
    #   to
    #   date_to
    #   time_to
    Segment.new(words[1], words[2], words[3])
  end
end
