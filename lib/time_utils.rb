# frozen_string_literal: true

require 'date'
require 'time'

# Utility methods to work with Time objects.
module TimeUtils
  # Parses a date string with an optional time string into a Time object.
  #
  # @param date [String] date in `YYYY-MM-DD` format.
  # @param time [String, nil] time in `HH:MM` format, or +nil+ for date-only.
  # @return [Time] the parsed time.
  def self.to_time(date, time)
    return datetime_to_time(date, time) if time

    date_to_time(date)
  end

  # Parses a date-only string into a Time object at midnight.
  #
  # @param date [String] date in `YYYY-MM-DD` format.
  # @return [Time] the parsed time at 00:00.
  def self.date_to_time(date)
    Time.strptime(date, '%Y-%m-%d')
  end

  # Parses a date and time string into a Time object.
  #
  # @param date [String] date in `YYYY-MM-DD` format.
  # @param time [String] time in `HH:MM` format.
  # @return [Time] the parsed datetime.
  def self.datetime_to_time(date, time)
    Time.strptime("#{date} #{time}", '%Y-%m-%d %H:%M')
  end

  # Formats a Time as a `YYYY-MM-DD HH:MM` string.
  #
  # @param datetime [Time] the time to format.
  # @return [String] datetime string.
  def self.datetime(datetime)
    datetime.strftime('%Y-%m-%d %H:%M')
  end

  # Formats a Time as a `YYYY-MM-DD` string (date).
  #
  # @param datetime [Time] the time to format.
  # @return [String] date string.
  def self.date(datetime)
    datetime.strftime('%Y-%m-%d')
  end

  # Formats a Time as a `HH:MM` string (time).
  #
  # @param datetime [Time] the time to format.
  # @return [String] time string.
  def self.time(datetime)
    datetime.strftime('%H:%M')
  end

  # Returns +true+ if two times has the exact same date.
  #
  # @param datetime1 [Time] first time.
  # @param datetime2 [Time] second time.
  # @return [Boolean]
  def self.same_dates?(datetime1, datetime2)
    datetime1.to_date == datetime2.to_date
  end

  # Returns the signed difference in hours between two Time objects.
  # A positive result means +next_date+ is later than +previous_date+.
  #
  # @param next_date [Time] the later Time.
  # @param previous_date [Time] the earlier Time.
  # @return [Float] difference in hours (can be negative).
  def self.hours_difference(next_date, previous_date)
    seconds_difference = next_date - previous_date
    seconds_difference / 3600 # seconds per hour
  end
end
