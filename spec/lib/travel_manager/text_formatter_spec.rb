# frozen_string_literal: true

require 'spec_helper'
require 'travel_manager'
require 'travel_manager/text_formatter'
require 'travel_manager/time_utils'

RSpec.describe TravelManager::TextFormatter do
  let(:flight_segment) do
    TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                               datetime_from: TravelManager::TimeUtils.to_time('2023-03-02', '06:40'),
                               datetime_to: TravelManager::TimeUtils.to_time('2023-03-02', '09:10'))
  end
  let(:train_segment) do
    TravelManager::Segment.new(type: 'Train', from: 'MAD', to: 'SVQ',
                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-17', '17:00'),
                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', '19:30'))
  end
  let(:hotel_segment) do
    TravelManager::Segment.new(type: 'Hotel', from: 'MAD', to: 'MAD',
                               datetime_from: TravelManager::TimeUtils.to_time('2023-02-15', nil),
                               datetime_to: TravelManager::TimeUtils.to_time('2023-02-17', nil))
  end

  describe '.trips_to_text' do
    context 'when the trips array is valid' do
      let(:expected_trips_text) do
        [
          [
            'TRIP to MAD',
            'Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10',
            'Hotel at MAD on 2023-02-15 to 2023-02-17',
            'Train from MAD to SVQ at 2023-02-17 17:00 to 19:30'
          ],
          [
            'TRIP to BCN',
            'Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10',
            'Hotel at MAD on 2023-02-15 to 2023-02-17',
            'Train from MAD to SVQ at 2023-02-17 17:00 to 19:30'
          ],
          [
            'TRIP to NYC',
            'Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10',
            'Hotel at MAD on 2023-02-15 to 2023-02-17',
            'Train from MAD to SVQ at 2023-02-17 17:00 to 19:30'
          ]
        ]
      end

      it 'returns the array of arrays with the right text' do
        trips = [
          TravelManager::Trip.new('MAD', [flight_segment, hotel_segment, train_segment]),
          TravelManager::Trip.new('BCN', [flight_segment, hotel_segment, train_segment]),
          TravelManager::Trip.new('NYC', [flight_segment, hotel_segment, train_segment])
        ]

        result = described_class.trips_to_text(trips)
        expect(result).to eq(expected_trips_text)
      end
    end

    context 'when the segment has an Unknown type' do
      it 'raises SegmentTypeNotCompatibleError' do
        trips = [TravelManager::Trip.new('BCN', [TravelManager::Segment.new(
          type: 'Car', from: 'MAD', to: 'BCN',
          datetime_from: TravelManager::TimeUtils.to_time('2026-03-02', '09:00'),
          datetime_to: TravelManager::TimeUtils.to_time('2026-03-02', '17:00')
        )])]

        expect do
          described_class.trips_to_text(trips)
        end.to raise_error(TravelManager::SegmentTypeNotCompatibleError, 'Unknown segment type: Car')
      end
    end

    context 'when the trips array is empty' do
      it 'returns nil' do
        trips = []

        result = described_class.trips_to_text(trips)
        expect(result).to be_nil
      end
    end
  end
end
