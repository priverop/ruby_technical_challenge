# frozen_string_literal: true

require 'spec_helper'
require 'finder'

RSpec.describe Finder do
  let(:unsorted_segments) do
    [
      Segment.new('Flight', 'SVQ', 'BCN', '2023-03-02', '2023-03-02', '06:40', '09:10'),
      Segment.new('Hotel', 'BCN', 'BCN', '2023-01-05', '2023-01-10', nil, nil),
      Segment.new('Flight', 'SVQ', 'BCN', '2023-01-05', '2023-01-05', '20:40', '22:10'),
      Segment.new('Flight', 'BCN', 'SVQ', '2023-01-10', '2023-01-10', '10:30', '11:50'),
      Segment.new('Train', 'SVQ', 'MAD', '2023-02-15', '2023-02-15', '9:30', '11:00'),
      Segment.new('Train', 'MAD', 'SVQ', '2023-02-17', '2023-02-17', '17:00', '19:30'),
      Segment.new('Hotel', 'MAD', 'MAD', '2023-02-15', '2023-02-17', nil, nil),
      Segment.new('Flight', 'BCN', 'NYC', '2023-03-02', '2023-03-02', '15:00', '22:45')
    ]
  end

  # Trips have sorted segments
  let(:trip_with_hotel) do
    [
      Segment.new('Flight', 'SVQ', 'BCN', '2023-01-05', '2023-01-05', '20:40', '22:10'),
      Segment.new('Hotel', 'BCN', 'BCN', '2023-01-05', '2023-01-10', nil, nil),
      Segment.new('Flight', 'BCN', 'SVQ', '2023-01-10', '2023-01-10', '10:30', '11:50')
    ]
  end

  let(:trip_without_hotel_same_day) do
    [
      Segment.new('Flight', 'SVQ', 'MAD', '2023-03-02', '2023-03-02', '06:40', '09:10'),
      Segment.new('Flight', 'MAD', 'NYC', '2023-03-02', '2023-03-02', '15:00', '22:45')
    ]
  end

  let(:trip_without_hotel_different_day) do
    [
      Segment.new('Flight', 'SVQ', 'MAD', '2023-03-02', '2023-03-02', '06:40', '09:10'),
      Segment.new('Flight', 'MAD', 'NYC', '2023-03-03', '2023-03-03', '7:00', '19:45')
    ]
  end

  describe '.find' do
    context 'when passing a valid segment' do
      it 'returns an array of Trips' do
        result = described_class.find(unsorted_segments, 'SVQ')

        expect(result.count).to eq(3)
        expect(result.first.destiny).to eq('BCN')
        expect(result.first.sorted_segments.count).to eq(3)
        expect(result.first.sorted_segments.last).to have_attributes(
          type: 'Flight',
          from: 'BCN',
          to: 'SVQ',
          datetime_from: TimeUtils.datetime_to_time('2023-01-10', '10:30'),
          datetime_to: TimeUtils.datetime_to_time('2023-01-10', '11:50')
        )
        expect(result.at(1).destiny).to eq('MAD')
        expect(result.at(1).sorted_segments.count).to eq(3)
        expect(result.at(1).sorted_segments.last).to have_attributes(
          type: 'Train',
          from: 'MAD',
          to: 'SVQ',
          datetime_from: TimeUtils.datetime_to_time('2023-02-17', '17:00'),
          datetime_to: TimeUtils.datetime_to_time('2023-02-17', '19:30')
        )
        expect(result.last.destiny).to eq('NYC')
        expect(result.last.sorted_segments.count).to eq(2)
        expect(result.last.sorted_segments.last).to have_attributes(
          type: 'Flight',
          from: 'BCN',
          to: 'NYC',
          datetime_from: TimeUtils.datetime_to_time('2023-03-02', '15:00'),
          datetime_to: TimeUtils.datetime_to_time('2023-03-02', '22:45')
        )
      end
    end
  end

  describe '.sorted_segments' do
    context 'when passing a valid array of segments' do
      it 'returns the sorted segments' do
        previous = Segment.new('Train', 'SVQ', 'MAD', '2023-02-15', '2023-02-15', '9:30', '11:00')

        result = described_class.sorted_segments(previous, unsorted_segments)

        expect(result.count).to eq(3)
        expect(result.last).to have_attributes(
          type: 'Train',
          from: 'MAD',
          to: 'SVQ',
          datetime_from: TimeUtils.datetime_to_time('2023-02-17', '17:00'),
          datetime_to: TimeUtils.datetime_to_time('2023-02-17', '19:30')
        )
      end
    end

    context 'when passing a nil segment as previous, and a valid array' do
      skip 'think, is this worth it?'
    end

    context 'when passing an empty array, with the previous segment' do
      it 'returns the previous segment' do
        previous = Segment.new('Flight', 'SVQ', 'BCN', '2023-01-05', '2023-01-05', '20:40', '22:10')

        result = described_class.sorted_segments(previous, [])

        expect(result).to eq([previous])
      end
    end
  end

  describe '.find_links' do
    context 'when the dates are the same' do
      it 'returns the correct next segment' do
        previous = Segment.new('Flight', 'SVQ', 'BCN', '2023-01-05', '2023-01-05', '20:40', '22:10')
        segments = [Segment.new('Hotel', 'BCN', 'BCN', '2023-01-05', '2023-01-10', nil, nil)]

        result = described_class.find_link(segments, previous)
        expect(result).to have_attributes(
          type: 'Hotel',
          from: 'BCN',
          to: 'BCN',
          datetime_from: TimeUtils.date_to_time('2023-01-05'),
          datetime_to: TimeUtils.date_to_time('2023-01-10')
        )
      end
    end

    context 'when the dates are different, but < 24h' do
      it 'returns the correct next segment' do
        previous = Segment.new('Train', 'SVQ', 'MAD', '2023-02-15', '2023-02-16', '15:00', '18:10')
        segments = unsorted_segments

        result = described_class.find_link(segments, previous)
        expect(result).to have_attributes(
          type: 'Train',
          from: 'MAD',
          to: 'SVQ',
          datetime_from: TimeUtils.datetime_to_time('2023-02-17', '17:00'),
          datetime_to: TimeUtils.datetime_to_time('2023-02-17', '19:30')
        )
      end
    end

    context 'when the dates are different, and > 24h' do
      it 'returns nil' do
        previous = Segment.new('Train', 'SVQ', 'MAD', '2023-02-15', '2023-02-16', '9:00', '12:10')
        segments = unsorted_segments

        result = described_class.find_link(segments, previous)
        expect(result).to be_nil
      end
    end
  end

  describe '.check_connection' do
    context 'when the flights time are < 24' do
      it 'returns true and sets the first segment as is_connection' do
        previous = trip_without_hotel_different_day.first
        next_segment = trip_without_hotel_different_day.last

        expect(previous.connection?).to be(false)
        result = described_class.check_connection(previous, next_segment)
        expect(result).to be(true)
        expect(previous.connection?).to be(true)
      end
    end

    context 'when the flights time are > 24' do
      it 'returns false and does nothing' do
        previous = trip_with_hotel.first
        next_segment = trip_with_hotel.last

        expect(previous.connection?).to be(false)
        result = described_class.check_connection(previous, next_segment)
        expect(result).to be(false)
        expect(previous.connection?).to be(false)
      end
    end

    context 'when only one is a flight' do
      it 'returns false and does_nothing' do
        previous = trip_with_hotel.first
        next_segment = trip_with_hotel.at(1)

        expect(previous.connection?).to be(false)
        result = described_class.check_connection(previous, next_segment)
        expect(result).to be(false)
        expect(previous.connection?).to be(false)
      end
    end

    context 'when they are the same flight' do
      it 'returns false and does_nothing' do
        previous = trip_with_hotel.first
        next_segment = trip_with_hotel.first

        expect(previous.connection?).to be(false)
        result = described_class.check_connection(previous, next_segment)
        expect(result).to be(false)
        expect(previous.connection?).to be(false)
      end
    end
  end

  describe '.find_trip_destiny' do
    context 'when no connection flights, and hotel' do
      it 'returns the first destiny' do
        result = described_class.find_trip_destiny(trip_with_hotel)

        expect(result).to be('BCN')
      end
    end

    context 'when no connection flights, flights same day' do
      it 'returns the first destiny' do
        result = described_class.find_trip_destiny(trip_without_hotel_same_day)

        expect(result).to be('MAD')
      end
    end

    context 'when no connection flights, no hotel, different days (layover)' do
      it 'returns the first destiny' do
        result = described_class.find_trip_destiny(trip_without_hotel_different_day)

        expect(result).to be('MAD')
      end
    end

    context 'when connection flights, flights same day, <24h' do
      it 'returns the first destiny' do
        trip_without_hotel_same_day.first.is_connection = true
        result = described_class.find_trip_destiny(trip_without_hotel_same_day)

        expect(result).to be('NYC')
      end
    end

    context 'when connection flights, no hotel, different days (layover)' do
      it 'returns the first destiny' do
        trip_without_hotel_different_day.first.is_connection = true
        result = described_class.find_trip_destiny(trip_without_hotel_different_day)

        expect(result).to be('NYC')
      end
    end
  end
end
