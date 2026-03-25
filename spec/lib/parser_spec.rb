# frozen_string_literal: true

require 'spec_helper'
require 'parser'

RSpec.describe Parser do
  let(:flight_line) { 'SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10' }
  let(:train_line) { 'SEGMENT: Train MAD 2023-02-17 17:00 -> SVQ 19:30' }
  let(:hotel_line) { 'SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10' }

  describe '.parse' do
    context 'when the input text file is valid' do
      it 'returns array of valid Segments' do
        skip 'TBD'
      end
    end

    context 'when the input is nil' do
      it 'returns empty array' do
        result = described_class.parse(nil)

        expect(result).to eq([])
      end
    end

    context 'when the input is empty string' do
      it 'returns empty array' do
        result = described_class.parse('')

        expect(result).to eq([])
      end
    end

    context 'when the input is only \n' do
      it 'returns empty array' do
        result = described_class.parse("\n")

        expect(result).to eq([])
      end
    end

    context 'when the input is only RESERVATION' do
      it 'returns empty array' do
        result = described_class.parse('RESERVATION')

        expect(result).to eq([])
      end
    end

    context 'when the input is RESERVATION and many \n' do
      it 'returns empty array' do
        result = described_class.parse("RESERVATION \n\n \n \n \n")

        expect(result).to eq([])
      end
    end
  end

  describe '.segment' do
    context 'when the text line has flight type' do
      it 'returns a valid Segment of type Flight' do
        result = described_class.segment(flight_line)

        expect(result).to have_attributes(
          type: 'Flight',
          from: 'SVQ',
          to: 'BCN',
          datetime_from: TimeUtils.datetime_to_time('2023-03-02', '06:40'),
          datetime_to: TimeUtils.datetime_to_time('2023-03-02', '09:10')
        )
      end
    end

    context 'when the text line has train type' do
      it 'returns a valid Segment of type Train' do
        result = described_class.segment(train_line)

        expect(result).to have_attributes(
          type: 'Train',
          from: 'MAD',
          to: 'SVQ',
          datetime_from: TimeUtils.datetime_to_time('2023-02-17', '17:00'),
          datetime_to: TimeUtils.datetime_to_time('2023-02-17', '19:30')
        )
      end
    end

    context 'when the text line has hotel type' do
      it 'returns a valid Segment of type Hotel' do
        result = described_class.segment(hotel_line)

        expect(result).to have_attributes(
          type: 'Hotel',
          from: 'BCN',
          to: 'BCN',
          datetime_from: TimeUtils.date_to_time('2023-01-05'),
          datetime_to: TimeUtils.date_to_time('2023-01-10')
        )
      end
    end

    context 'when the text line has no SEGMENT: part' do
      it 'returns nil' do
        result = described_class.segment('Train MAD 2023-02-17 17:00 -> SVQ 19:30')

        expect(result).to be_nil
      end
    end

    context 'when the text line has SEGMENT: but the rest is empty' do
      it 'returns nil' do
        result = described_class.segment('SEGMENT: ')

        expect(result).to be_nil
      end
    end
  end

  describe '.trip_segment' do
    context 'when flight line matches the pattern' do
      it 'returns a valid Segment type Flight' do
        result = described_class.trip_segment(flight_line)

        expect(result).to have_attributes(
          type: 'Flight',
          from: 'SVQ',
          to: 'BCN',
          datetime_from: TimeUtils.datetime_to_time('2023-03-02', '06:40'),
          datetime_to: TimeUtils.datetime_to_time('2023-03-02', '09:10')
        )
      end
    end

    context 'when train line matches the pattern' do
      it 'returns a valid Segment type Train' do
        result = described_class.trip_segment(train_line)

        expect(result).to have_attributes(
          type: 'Train',
          from: 'MAD',
          to: 'SVQ',
          datetime_from: TimeUtils.datetime_to_time('2023-02-17', '17:00'),
          datetime_to: TimeUtils.datetime_to_time('2023-02-17', '19:30')
        )
      end
    end

    context 'when the line doesn\'t match the pattern' do
      it 'return nil' do
        result = described_class.trip_segment(hotel_line)

        expect(result).to be_nil
      end
    end
  end

  describe '.hotel_segment' do
    context 'when hotel line matches the pattern' do
      it 'returns a valid Segment of type Hotel' do
        result = described_class.hotel_segment(hotel_line)

        expect(result).to have_attributes(
          type: 'Hotel',
          from: 'BCN',
          to: 'BCN',
          datetime_from: TimeUtils.date_to_time('2023-01-05'),
          datetime_to: TimeUtils.date_to_time('2023-01-10')
        )
      end
    end

    context 'when the line doesn\'t match the pattern' do
      it 'return nil' do
        result = described_class.hotel_segment(flight_line)

        expect(result).to be_nil
      end
    end
  end
end
