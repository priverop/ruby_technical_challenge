# frozen_string_literal: true

require 'time'

# Help methods to work with Time
module TimeUtils
  def self.to_time(date, time) # TODO: is this ok? looks ugly
    return datetime_to_time(date, time) if date && time

    date_to_time(date)
  end

  def self.date_to_time(date)
    Time.strptime(date, '%Y-%m-%d')
  end

  def self.datetime_to_time(date, time)
    Time.strptime("#{date} #{time}", '%Y-%m-%d %H:%M')
  end

  def self.datetime(time)
    time.strftime('%Y-%m-%d %H:%M')
  end

  def self.date(time)
    time.strftime('%Y-%m-%d')
  end

  def self.hour(time)
    time.strftime('%H:%M')
  end

  def self.same_dates?(datetime1, datetime2)
    datetime1.strftime('%Y-%m-%d') == datetime2.strftime('%Y-%m-%d')
  end
end
