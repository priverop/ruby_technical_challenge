# frozen_string_literal: true

class Finder
  def self.find(segments, based)
    sorted = []
    # TODO: en vez de first, se hace un bucle, que llama al LINKER
    previous = segments.select{ |segment| segment.from == based }
                      .sort_by { |segment| segment.date_from }
                      .first # TODO: maybe instead o getting the first one, we should

    loop do
      sorted.push(previous)
      previous = link(segments, previous)
      break if previous.nil?
    end

    sorted
  end

  def self.link(segments, previous)
    segments.select{ |segment| segment.from == previous.to && segment.date_from == previous.date_to }.first
  end
end
