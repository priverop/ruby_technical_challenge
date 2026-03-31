# frozen_string_literal: true

require 'spec_helper'
require 'travel_manager'
require 'travel_manager/segment'
require 'travel_manager/trip_builder'

RSpec.describe TravelManager::TripBuilder do
  let(:unsorted_segments) do
    [
      TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '06:40'),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '09:10')),
      TravelManager::Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', nil),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', nil)),
      TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')),
      TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50')),
      TravelManager::Segment.new(type: 'Train', from: 'SVQ', to: 'MAD',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-02-15', '9:30'),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-02-15', '11:00')),
      TravelManager::Segment.new(type: 'Train', from: 'MAD', to: 'SVQ',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-02-17', '17:00'),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', '19:30')),
      TravelManager::Segment.new(type: 'Hotel', from: 'MAD', to: 'MAD',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-02-15', nil),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', nil)),
      TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'NYC',
                                 datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '15:00'),
                                 datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '22:45'))
    ]
  end

  let(:overnight_flight) do
    TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'MAD',
                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-15', '15:00'),
                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-16', '18:10'))
  end

  describe '.build' do
    context 'when passing valid segments' do
      it 'returns a valid array of Trips' do
        result = described_class.build(unsorted_segments, 'SVQ')

        expect(result.count).to eq(3)
        expect(result.first.destination).to eq('BCN')
        expect(result.first.sorted_segments.count).to eq(3)
        expect(result.first.sorted_segments.last).to have_attributes(
          type: 'Flight',
          from: 'BCN',
          to: 'SVQ',
          datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
          datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50')
        )
        expect(result.at(1).destination).to eq('MAD')
        expect(result.at(1).sorted_segments.count).to eq(3)
        expect(result.at(1).sorted_segments.last).to have_attributes(
          type: 'Train',
          from: 'MAD',
          to: 'SVQ',
          datetime_from: TravelManager::TimeUtils.to_time('2023-02-17', '17:00'),
          datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', '19:30')
        )
        expect(result.last.destination).to eq('NYC')
        expect(result.last.sorted_segments.count).to eq(2)
        expect(result.last.sorted_segments.last).to have_attributes(
          type: 'Flight',
          from: 'BCN',
          to: 'NYC',
          datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '15:00'),
          datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '22:45')
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
          TravelManager::Segment.new(type: 'Flight', from: 'NYC', to: 'LAX',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '06:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '09:10')),
          TravelManager::Segment.new(type: 'Hotel', from: 'LAX', to: 'NYC',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-03-05', '09:00'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-03-05', '12:00')),
          TravelManager::Segment.new(type: 'Flight', from: 'NYC', to: 'JFK',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-06-02', '15:00'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-06-02', '22:45')),
          TravelManager::Segment.new(type: 'Flight', from: 'JFK', to: 'NYC',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-06-04', '15:00'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-06-04', '22:45'))
        ]

        result = described_class.build(unsorted_segments, based)

        expect(result.count).to eq(2)
        expect(result.first.destination).to eq('LAX')
        expect(result.first.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'NYC', to: 'LAX',
          datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '06:40'),
          datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '09:10')
        )
        expect(result.last.destination).to eq('JFK')
        expect(result.last.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'NYC', to: 'JFK',
          datetime_from: TravelManager::TimeUtils.to_time('2023-06-02', '15:00'),
          datetime_to: TravelManager::TimeUtils.to_time('2023-06-02', '22:45')
        )
      end
    end

    context 'when passing single segment' do
      it 'returns the segment' do
        segments = [TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10'))]

        result = described_class.build(segments, 'SVQ')

        expect(result.count).to eq(1)
        expect(result.first.destination).to eq('BCN')
        expect(result.first.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'SVQ', to: 'BCN',
          datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
          datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')
        )
      end
    end

    context 'when the dates are different, but < 24h (connection flights)' do
      it 'returns the trip destination to SVQ' do
        segments = [overnight_flight,
                    TravelManager::Segment.new(type: 'Flight', from: 'MAD', to: 'SVQ',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-17', '17:00'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', '19:30'))]

        result = described_class.build(segments, 'SVQ')

        expect(result.count).to eq(1)
        expect(result.first.destination).to eq('SVQ')
        expect(result.first.sorted_segments.count).to eq(2)
        expect(result.first.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'SVQ', to: 'MAD',
          is_connection: true
        )
        expect(result.first.sorted_segments.last).to have_attributes(
          type: 'Flight', from: 'MAD', to: 'SVQ',
          is_connection: nil
        )
      end
    end

    context 'when the dates are different, and > 24h (no connection flights)' do
      it 'returns the trip destination to MAD' do
        segments = [overnight_flight,
                    TravelManager::Segment.new(type: 'Flight', from: 'MAD', to: 'SVQ',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-17', '18:20'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', '19:30'))]

        result = described_class.build(segments, 'SVQ')

        expect(result.count).to eq(1)
        expect(result.first.destination).to eq('MAD')
        expect(result.first.sorted_segments.count).to eq(1)
        expect(result.first.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'SVQ', to: 'MAD',
          is_connection: nil
        )
      end
    end

    context 'when the segments are exactly 24.0h appart' do
      it 'behaves as <24h (connection flights)' do
        segments = [TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'MAD',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-15', '15:00'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-15', '18:10')),
                    TravelManager::Segment.new(type: 'Flight', from: 'MAD', to: 'SVQ',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-16', '18:10'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', '19:30'))]

        result = described_class.build(segments, 'SVQ')

        expect(result.count).to eq(1)
        expect(result.first.destination).to eq('SVQ')
        expect(result.first.sorted_segments.count).to eq(2)
        expect(result.first.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'SVQ', to: 'MAD',
          is_connection: true
        )
        expect(result.first.sorted_segments.last).to have_attributes(
          type: 'Flight', from: 'MAD', to: 'SVQ',
          is_connection: nil
        )
      end
    end

    # requirements say only two flights can be considered connections
    context 'when there is a connection travel, but its not a flight' do
      it 'returns the correct next segment' do
        segments = [overnight_flight,
                    TravelManager::Segment.new(type: 'Train', from: 'MAD', to: 'SVQ',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-17', '17:00'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', '19:30'))]

        result = described_class.build(segments, 'SVQ')

        expect(result.count).to eq(1)
        expect(result.first.destination).to eq('MAD')
        expect(result.first.sorted_segments.count).to eq(2)
        expect(result.first.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'SVQ', to: 'MAD',
          is_connection: false
        )
        expect(result.first.sorted_segments.last).to have_attributes(
          type: 'Train', from: 'MAD', to: 'SVQ',
          is_connection: nil
        )
      end
    end

    context 'when same day round trip' do
      # avoid infinte loop
      it 'returns the SVQ trip' do
        segments = [TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'MAD',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-15', '08:00'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-15', '10:00')),
                    TravelManager::Segment.new(type: 'Flight', from: 'MAD', to: 'SVQ',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-15', '18:00'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-15', '20:00'))]

        result = described_class.build(segments, 'SVQ')

        expect(result.count).to eq(1)
        expect(result.first.destination).to eq('SVQ')
        expect(result.first.sorted_segments.count).to eq(2)
        expect(result.first.sorted_segments.first).to have_attributes(
          type: 'Flight', from: 'SVQ', to: 'MAD',
          is_connection: true
        )
        expect(result.first.sorted_segments.last).to have_attributes(
          type: 'Flight', from: 'MAD', to: 'SVQ',
          is_connection: nil
        )
      end
    end

    context 'when multiple connection flights' do
      it 'returns the right destination' do
        segments = [
          TravelManager::Segment.new(type: 'Flight', from: 'NYC', to: 'JFK',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '06:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '09:10')),
          TravelManager::Segment.new(type: 'Flight', from: 'JFK', to: 'ORD',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '11:00'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '13:00')),
          TravelManager::Segment.new(type: 'Flight', from: 'ORD', to: 'LAX',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '15:00'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '17:45'))
        ]

        result = described_class.build(segments, 'NYC')

        expect(result.count).to eq(1)
        expect(result.first.destination).to eq('LAX')
        expect(result.first.sorted_segments.count).to eq(3)
        expect(result.first.sorted_segments[0]).to have_attributes(
          type: 'Flight', from: 'NYC', to: 'JFK',
          is_connection: true
        )
        expect(result.first.sorted_segments[1]).to have_attributes(
          type: 'Flight', from: 'JFK', to: 'ORD',
          is_connection: true
        )
        expect(result.first.sorted_segments[2]).to have_attributes(
          type: 'Flight', from: 'ORD', to: 'LAX',
          is_connection: nil
        )
      end
    end
  end
end
