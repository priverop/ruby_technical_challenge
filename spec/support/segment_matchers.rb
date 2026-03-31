# frozen_string_literal: true

RSpec::Matchers.define :match_segments do |expected|
  match do |actual|
    segment_attributes(actual) == segment_attributes(expected)
  end

  failure_message do |actual|
    "expected segments:\n#{segment_attributes(actual)}\nto match:\n#{segment_attributes(expected)}"
  end

  def segment_attributes(segments)
    Array(segments).map do |s|
      { type: s.type, from: s.from, to: s.to,
        datetime_from: s.datetime_from, datetime_to: s.datetime_to }
    end
  end
end
