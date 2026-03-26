# frozen_string_literal: true

require 'spec_helper'
require 'itinerary'

RSpec.describe Itinerary do
  let(:flight_segment) { Segment.new('Flight', 'SVQ', 'BCN', '2023-03-02', '2023-03-02', '06:40', '09:10') }
  let(:train_segment) { Segment.new('Train', 'MAD', 'SVQ', '2023-02-17', '2023-02-17', '17:00', '19:30') }
  let(:hotel_segment) { Segment.new('Hotel', 'MAD', 'MAD', '2023-02-15', '2023-02-17', nil, nil) }

  let(:train_generic_travel_text) { 'from MAD to SVQ at 2023-02-17 17:00 to 19:30' }
  let(:flight_generic_travel_text) { 'from SVQ to BCN at 2023-03-02 06:40 to 09:10' }

  let(:flight_travel_text){ 'Flight from SVQ to BCN at 2023-03-02 06:40 to 09:10' }
  let(:train_travel_text){ 'Train from MAD to SVQ at 2023-02-17 17:00 to 19:30' }
  let(:hotel_text){ 'Hotel at MAD on 2023-02-15 to 2023-02-17' }

  describe '.generate' do
    context 'when the trips array is valid' do
      it 'returns the array of arrays with the right text' do
        skip 'TBD'
      end
    end
  end

  describe '.trip_to_text' do
    context 'when the trip object is valid' do
      it 'returns the array of segment with the TRIP header' do
        skip 'TBD'
      end
    end
  end

  describe '.segment_to_text' do
    context 'when the segment is type Flight' do
      it 'delegates to flight_to_text' do
        allow(described_class).to receive(:flight_to_text).with(flight_segment).and_return(flight_travel_text)

        result = described_class.segment_to_text(flight_segment)
        expect(result).to eq(flight_travel_text)
      end
    end

    context 'when the segment is type Train' do
      it 'delegates to train_to_text' do
        allow(described_class).to receive(:train_to_text).with(train_segment).and_return(train_travel_text)

        result = described_class.segment_to_text(train_segment)
        expect(result).to eq(train_travel_text)
      end
    end

    context 'when the segment is type Hotel' do
      it 'delegates to hotel_to_text' do
        allow(described_class).to receive(:hotel_to_text).with(hotel_segment).and_return(hotel_text)

        result = described_class.segment_to_text(hotel_segment)
        expect(result).to eq(hotel_text)
      end
    end
  end

  describe '.hotel_to_text' do
    context 'when the hotel segment is valid' do
      it 'returns the hotel text' do
        result = described_class.hotel_to_text(hotel_segment)
        expected = hotel_text

        expect(result).to eq(expected)
      end
    end
  end

  describe '.flight_to_text' do
    context 'when the flight segment is valid' do
      it 'returns the flight text' do
        allow(described_class).to receive(:travel_to_text).and_return(flight_generic_travel_text)

        result = described_class.flight_to_text(flight_segment)
        expected = flight_travel_text

        expect(result).to eq(expected)
      end
    end
  end

  describe '.train_to_text' do
    context 'when the train segment is valid' do
      it 'returns the train text' do
        allow(described_class).to receive(:travel_to_text).and_return(train_generic_travel_text)

        result = described_class.train_to_text(train_segment)
        expected = train_travel_text

        expect(result).to eq(expected)
      end
    end
  end

  describe '.travel_to_text' do
    context 'when the flight segment is valid' do
      it 'returns the generic trip text' do
        result = described_class.travel_to_text(flight_segment)
        expected = flight_generic_travel_text

        expect(result).to eq(expected)
      end
    end

    context 'when the train segment is valid' do
      it 'returns the generic trip text' do
        result = described_class.travel_to_text(train_segment)
        expected = train_generic_travel_text

        expect(result).to eq(expected)
      end
    end
  end
end
