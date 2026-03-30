# frozen_string_literal: true

require 'spec_helper'
require 'trip_builder'

RSpec.describe TripBuilder do
  let(:unsorted_segments) do
    [
      Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                  datetime_from: TimeUtils.to_time('2023-03-02', '06:40'),
                  datetime_to: TimeUtils.to_time('2023-03-02', '09:10')),
      Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                  datetime_from: TimeUtils.to_time('2023-01-05', nil),
                  datetime_to: TimeUtils.to_time('2023-01-10', nil)),
      Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                  datetime_from: TimeUtils.to_time('2023-01-05', '20:40'),
                  datetime_to: TimeUtils.to_time('2023-01-05', '22:10')),
      Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                  datetime_from: TimeUtils.to_time('2023-01-10', '10:30'),
                  datetime_to: TimeUtils.to_time('2023-01-10', '11:50')),
      Segment.new(type: 'Train', from: 'SVQ', to: 'MAD',
                  datetime_from: TimeUtils.to_time('2023-02-15', '9:30'),
                  datetime_to: TimeUtils.to_time('2023-02-15', '11:00')),
      Segment.new(type: 'Train', from: 'MAD', to: 'SVQ',
                  datetime_from: TimeUtils.to_time('2023-02-17', '17:00'),
                  datetime_to: TimeUtils.to_time('2023-02-17', '19:30')),
      Segment.new(type: 'Hotel', from: 'MAD', to: 'MAD',
                  datetime_from: TimeUtils.to_time('2023-02-15', nil),
                  datetime_to: TimeUtils.to_time('2023-02-17', nil)),
      Segment.new(type: 'Flight', from: 'BCN', to: 'NYC',
                  datetime_from: TimeUtils.to_time('2023-03-02', '15:00'),
                  datetime_to: TimeUtils.to_time('2023-03-02', '22:45'))
    ]
  end

  describe '.build' do
    context 'when passing valid segments' do
      it 'returns a valid array of Trips' do # TODO: assert everything? decompose?
        result = described_class.build(unsorted_segments, 'SVQ')

        expect(result.count).to eq(3)
        expect(result.first.destination).to eq('BCN')
        expect(result.first.sorted_segments.count).to eq(3)
        expect(result.first.sorted_segments.last).to have_attributes(
          type: 'Flight',
          from: 'BCN',
          to: 'SVQ',
          datetime_from: TimeUtils.to_time('2023-01-10', '10:30'),
          datetime_to: TimeUtils.to_time('2023-01-10', '11:50')
        )
        expect(result.at(1).destination).to eq('MAD')
        expect(result.at(1).sorted_segments.count).to eq(3)
        expect(result.at(1).sorted_segments.last).to have_attributes(
          type: 'Train',
          from: 'MAD',
          to: 'SVQ',
          datetime_from: TimeUtils.to_time('2023-02-17', '17:00'),
          datetime_to: TimeUtils.to_time('2023-02-17', '19:30')
        )
        expect(result.last.destination).to eq('NYC')
        expect(result.last.sorted_segments.count).to eq(2)
        expect(result.last.sorted_segments.last).to have_attributes(
          type: 'Flight',
          from: 'BCN',
          to: 'NYC',
          datetime_from: TimeUtils.to_time('2023-03-02', '15:00'),
          datetime_to: TimeUtils.to_time('2023-03-02', '22:45')
        )
      end
    end

    context 'when passing segments with no based_segments' do
      it 'returns nil' do
        based = 'ALC'

        result = described_class.build(unsorted_segments, based)
        expect(result).to be_nil
      end
    end

    context 'when passing based segments with no extra linkeable segments' do
      # Use case: they forgot to make the hotel reservations.
      it 'returns only the based segments' do
        based = 'NYC'

        unsorted_segments = [
          Segment.new(type: 'Flight', from: 'NYC', to: 'LAX',
                      datetime_from: TimeUtils.to_time('2023-03-02', '06:40'),
                      datetime_to: TimeUtils.to_time('2023-03-02', '09:10')),
          Segment.new(type: 'Hotel', from: 'LAX', to: 'NYC',
                      datetime_from: TimeUtils.to_time('2023-03-05', '09:00'),
                      datetime_to: TimeUtils.to_time('2023-03-05', '12:00')),
          Segment.new(type: 'Flight', from: 'NYC', to: 'JFK',
                      datetime_from: TimeUtils.to_time('2023-06-02', '15:00'),
                      datetime_to: TimeUtils.to_time('2023-06-02', '22:45')),
          Segment.new(type: 'Flight', from: 'JFK', to: 'NYC',
                      datetime_from: TimeUtils.to_time('2023-06-04', '15:00'),
                      datetime_to: TimeUtils.to_time('2023-06-04', '22:45'))
        ]

        result = described_class.build(unsorted_segments, based)

        expect(result.count).to eq(2)
        expect(result.first.destination).to eq('LAX')
        expect(result.first.sorted_segments).to eq([unsorted_segments.first])
        expect(result.last.destination).to eq('JFK')
        expect(result.last.sorted_segments).to eq([unsorted_segments[2]])
      end
    end

    context 'when passing single segment' do # TODO: remove?
      it 'returns the segment' do
        segments = [Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                datetime_from: TimeUtils.to_time('2023-01-05', '20:40'),
                                datetime_to: TimeUtils.to_time('2023-01-05', '22:10'))]

        result = described_class.build(segments, 'SVQ')
        expect(result).to eq([Trip.new('BCN', segments)])
      end
    end

    context 'when the dates are different, but < 24h (connection flights)' do
      it 'returns the trip destination to SVQ' do
        segments = [Segment.new(type: 'Flight', from: 'SVQ', to: 'MAD',
                                datetime_from: TimeUtils.to_time('2023-02-15', '15:00'),
                                datetime_to: TimeUtils.to_time('2023-02-16', '18:10')),
                    Segment.new(type: 'Flight', from: 'MAD', to: 'SVQ',
                                datetime_from: TimeUtils.to_time('2023-02-17', '17:00'),
                                datetime_to: TimeUtils.to_time('2023-02-17', '19:30'))]

        result = described_class.build(segments, 'SVQ')
        expect(result).to eq([Trip.new('SVQ', segments)])
      end
    end

    context 'when the dates are different, and > 24h (no connection flights)' do
      it 'returns the trip destination to MAD' do
        segments = [Segment.new(type: 'Flight', from: 'SVQ', to: 'MAD',
                                datetime_from: TimeUtils.to_time('2023-02-15', '15:00'),
                                datetime_to: TimeUtils.to_time('2023-02-16', '18:10')),
                    Segment.new(type: 'Flight', from: 'MAD', to: 'SVQ',
                                datetime_from: TimeUtils.to_time('2023-02-17', '18:20'),
                                datetime_to: TimeUtils.to_time('2023-02-17', '19:30'))]

        result = described_class.build(segments, 'SVQ')
        expect(result).to eq([Trip.new('MAD', [segments.first])])
      end
    end

    # requirements say only two flights can be considered connections
    context 'when there is a connection travel, but its not a flight' do
      it 'returns the correct next segment' do
        segments = [Segment.new(type: 'Flight', from: 'SVQ', to: 'MAD',
                                datetime_from: TimeUtils.to_time('2023-02-15', '15:00'),
                                datetime_to: TimeUtils.to_time('2023-02-16', '18:10')),
                    Segment.new(type: 'Train', from: 'MAD', to: 'SVQ',
                                datetime_from: TimeUtils.to_time('2023-02-17', '17:00'),
                                datetime_to: TimeUtils.to_time('2023-02-17', '19:30'))]

        result = described_class.build(segments, 'SVQ')
        expect(result).to eq([Trip.new('MAD', segments)])
      end
    end

    context 'when same day round trip' do
      # avoid infinte loop
      it 'returns the SVQ trip' do
        segments = [Segment.new(type: 'Flight', from: 'SVQ', to: 'MAD',
                                datetime_from: TimeUtils.to_time('2023-02-15', '08:00'),
                                datetime_to: TimeUtils.to_time('2023-02-15', '10:00')),
                    Segment.new(type: 'Flight', from: 'MAD', to: 'SVQ',
                                datetime_from: TimeUtils.to_time('2023-02-15', '18:00'),
                                datetime_to: TimeUtils.to_time('2023-02-15', '20:00'))]

        result = described_class.build(segments, 'SVQ')
        expect(result).to eq([Trip.new('SVQ', segments)]) # TODO: bug or feature?
      end
    end
  end
end
