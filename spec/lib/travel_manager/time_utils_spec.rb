# frozen_string_literal: true

require 'spec_helper'
require 'travel_manager'
require 'travel_manager/time_utils'

RSpec.describe TravelManager::TimeUtils do
  describe '.to_time' do
    context 'when date and time are present' do
      it 'returns a Time with date and time' do
        result = described_class.to_time('2023-03-02', '06:40')

        expect(result).to eq(Time.utc(2023, 3, 2, 6, 40))
      end
    end

    context 'when time is nil' do
      it 'returns a Time at midnight' do
        result = described_class.to_time('2023-03-02', nil)

        expect(result).to eq(Time.utc(2023, 3, 2, 0, 0))
      end
    end
  end

  describe '.arrival_time' do
    context 'when arrival time is after departure time' do
      it 'returns arrival on the same day' do
        result = described_class.arrival_time('2023-03-02', '06:40', '09:10')

        expect(result).to eq(Time.utc(2023, 3, 2, 9, 10))
      end
    end

    context 'when arrival time is before departure time (overnight)' do
      it 'returns arrival on the next day' do
        result = described_class.arrival_time('2023-03-02', '23:00', '02:30')

        expect(result).to eq(Time.utc(2023, 3, 3, 2, 30))
      end
    end

    context 'when arrival time is midnight (overnight)' do
      it 'returns arrival on the next day' do
        result = described_class.arrival_time('2023-03-02', '23:59', '00:00')

        expect(result).to eq(Time.utc(2023, 3, 3, 0, 0))
      end
    end

    context 'when arrival and departure times are the same' do
      it 'returns arrival on the same day' do
        result = described_class.arrival_time('2023-03-02', '10:00', '10:00')

        expect(result).to eq(Time.utc(2023, 3, 2, 10, 0))
      end
    end

    context 'when the overnight flight crosses a DST spring-forward transition' do
      around do |example|
        original_tz = ENV.fetch('TZ', nil)
        ENV['TZ'] = 'America/New_York'
        example.run
        ENV['TZ'] = original_tz
      end

      it 'returns the correct arrival time unaffected by DST' do
        result = described_class.arrival_time('2023-03-11', '23:00', '02:30')

        expect(result).to eq(Time.utc(2023, 3, 12, 2, 30))
      end
    end

    context 'when the overnight flight crosses a DST fall-back transition' do
      around do |example|
        original_tz = ENV.fetch('TZ', nil)
        ENV['TZ'] = 'America/New_York'
        example.run
        ENV['TZ'] = original_tz
      end

      it 'returns the correct arrival time unaffected by DST' do
        result = described_class.arrival_time('2023-11-04', '23:00', '02:30')

        expect(result).to eq(Time.utc(2023, 11, 5, 2, 30))
      end
    end
  end

  describe '.datetime' do
    it 'formats a Time as YYYY-MM-DD HH:MM' do
      result = described_class.datetime(Time.utc(2023, 3, 2, 6, 40))

      expect(result).to eq('2023-03-02 06:40')
    end
  end

  describe '.date' do
    it 'formats a Time as YYYY-MM-DD' do
      result = described_class.date(Time.utc(2023, 3, 2, 6, 40))

      expect(result).to eq('2023-03-02')
    end
  end

  describe '.time' do
    it 'formats a Time as HH:MM' do
      result = described_class.time(Time.utc(2023, 3, 2, 6, 40))

      expect(result).to eq('06:40')
    end
  end

  describe '.hours_difference' do
    context 'when next day but same time' do
      it 'returns 24' do
        a = Time.utc(2026, 3, 2, 9, 0)
        b = Time.utc(2026, 3, 3, 9, 0)

        result = described_class.hours_difference(b, a)

        expect(result).to eq(24)
      end
    end

    context 'when same days but different time' do
      it 'returns the exact hour difference' do
        a = Time.utc(2026, 3, 2, 6, 0)
        b = Time.utc(2026, 3, 2, 15, 0)

        result = described_class.hours_difference(b, a)

        expect(result).to eq(9)
      end
    end

    context 'when the first date is earlier than the second' do
      it 'returns negative' do
        a = Time.utc(2023, 2, 15, 0, 0)
        b = Time.utc(2023, 2, 16, 12, 10)

        result = described_class.hours_difference(a, b)

        expect(result).to be < 0
      end
    end

    context 'when same days but different month' do
      it 'returns value bigger than 24' do
        a = Time.utc(2026, 3, 2, 9, 0)
        b = Time.utc(2026, 4, 2, 9, 0)

        result = described_class.hours_difference(b, a)

        expect(result).to be > 24
      end
    end

    context 'when the dates are the same' do
      it 'returns 0' do
        a = Time.utc(2026, 3, 2, 9, 30)
        b = Time.utc(2026, 3, 2, 9, 30)

        result = described_class.hours_difference(a, b)

        expect(result).to eq(0)
      end
    end
  end
end
