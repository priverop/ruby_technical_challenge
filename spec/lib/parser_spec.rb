# frozen_string_literal: true

require 'spec_helper'
require 'parser'

RSpec.describe Parser do
  let(:flight_line) { 'SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10' }
  let(:train_line) { 'SEGMENT: Train MAD 2023-02-17 17:00 -> SVQ 19:30' }
  let(:hotel_line) { 'SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10' }

  let(:flight_segment) do
    Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                datetime_from: TimeUtils.to_time('2023-03-02', '06:40'),
                datetime_to: TimeUtils.to_time('2023-03-02', '09:10'))
  end
  let(:train_segment) do
    Segment.new(type: 'Train', from: 'MAD', to: 'SVQ',
                datetime_from: TimeUtils.to_time('2023-02-17', '17:00'),
                datetime_to: TimeUtils.to_time('2023-02-17', '19:30'))
  end
  let(:hotel_segment) do
    Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                datetime_from: TimeUtils.to_time('2023-01-05', nil),
                datetime_to: TimeUtils.to_time('2023-01-10', nil))
  end

  let(:expected_segments) do
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

  describe '.parse' do
    context 'when the input text file is valid' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10

          RESERVATION
          SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
          SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50

          RESERVATION
          SEGMENT: Train SVQ 2023-02-15 09:30 -> MAD 11:00
          SEGMENT: Train MAD 2023-02-17 17:00 -> SVQ 19:30

          RESERVATION
          SEGMENT: Hotel MAD 2023-02-15 -> 2023-02-17

          RESERVATION
          SEGMENT: Flight BCN 2023-03-02 15:00 -> NYC 22:45
        TEXT
      end

      it 'returns array of valid Segments' do
        result = described_class.parse(input_reservations)
        expect(result).to eq(expected_segments)
      end
    end

    context 'when the input text file is valid and smaller' do
      let(:small_input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
          SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50
        TEXT
      end

      it 'returns array of valid Segments' do
        expected = [
          Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                      datetime_from: TimeUtils.to_time('2023-01-05', nil),
                      datetime_to: TimeUtils.to_time('2023-01-10', nil)),
          Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                      datetime_from: TimeUtils.to_time('2023-01-05', '20:40'),
                      datetime_to: TimeUtils.to_time('2023-01-05', '22:10')),
          Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                      datetime_from: TimeUtils.to_time('2023-01-10', '10:30'),
                      datetime_to: TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(small_input_reservations)
        expect(result).to eq(expected)
      end
    end

    context 'when the input text file has hotel line without SEGMENT:' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          Hotel BCN 2023-01-05 -> 2023-01-10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
          SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50
        TEXT
      end

      it 'ignored the hotel line and returns array of flight Segments' do
        expected = [
          Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                      datetime_from: TimeUtils.to_time('2023-01-05', '20:40'),
                      datetime_to: TimeUtils.to_time('2023-01-05', '22:10')),
          Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                      datetime_from: TimeUtils.to_time('2023-01-10', '10:30'),
                      datetime_to: TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to eq(expected)
      end
    end

    context 'when the input text file has lines without time:' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 -> BCN
          SEGMENT: Flight BCN 2023-01-10 -> SVQ
        TEXT
      end

      it 'ignores the fligh lines and returns hotel Segments' do
        expected = [
          Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                      datetime_from: TimeUtils.to_time('2023-01-05', nil),
                      datetime_to: TimeUtils.to_time('2023-01-10', nil))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to eq(expected)
      end
    end

    context 'when the input text file has malformed dates' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT: Hotel BCN 01-01-2023 -> 01-01-2023

          RESERVATION
          SEGMENT: Flight SVQ TODAY 20:40 -> BCN 22:10
          SEGMENT: Train BCN 2023-01-10 10:30 -> SVQ 11:50
        TEXT
      end

      it 'ignores hotel and flight and returns array of the train Segments' do
        expected = [
          Segment.new(type: 'Train', from: 'BCN', to: 'SVQ',
                      datetime_from: TimeUtils.to_time('2023-01-10', '10:30'),
                      datetime_to: TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to eq(expected)
      end
    end

    context 'when the input text file has hotel line without Hotel' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT: BCN 2023-01-05 -> 2023-01-10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
          SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50
        TEXT
      end

      it 'raises SegmentTypeNotCompatibleError of valid Segments' do
        expect do
          described_class.parse(input_reservations)
        end.to raise_error(TravelManager::SegmentTypeNotCompatibleError, 'Unknown segment type: BCN')
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

  describe '.segment' do # TODO: redo with the new send
    context 'when the text line has flight type' do
      it 'delegates to trip_segment' do
        allow(described_class).to receive(:flight_segment).with(flight_line).and_return(flight_segment)
        result = described_class.send(:segment, flight_line)

        expect(result).to eq(flight_segment)
      end
    end

    context 'when the text line has train type' do
      it 'delegates to trip_segment' do
        allow(described_class).to receive(:train_segment).with(train_line).and_return(train_segment)
        result = described_class.send(:segment, train_line)

        expect(result).to eq(train_segment)
      end
    end

    context 'when the text line has hotel type' do
      it 'delegates to hotel_segment' do
        allow(described_class).to receive(:hotel_segment).with(hotel_line).and_return(hotel_segment)
        result = described_class.send(:segment, hotel_line)

        expect(result).to eq(hotel_segment)
      end
    end

    context 'when the text line has no SEGMENT: part' do
      it 'returns nil' do
        result = described_class.send(:segment, 'Train MAD 2023-02-17 17:00 -> SVQ 19:30')

        expect(result).to be_nil
      end
    end

    context 'when the text line has SEGMENT: but the rest is empty' do
      it 'returns nil' do
        result = described_class.send(:segment, 'SEGMENT: ')

        expect(result).to be_nil
      end
    end
  end

  describe '.trip_segment' do
    context 'when flight line matches the pattern' do
      it 'returns a valid Segment type Flight' do
        result = described_class.send(:trip_segment, flight_line)

        expect(result).to eq(flight_segment)
      end
    end

    context 'when train line matches the pattern' do
      it 'returns a valid Segment type Train' do
        result = described_class.send(:trip_segment, train_line)

        expect(result).to eq(train_segment)
      end
    end

    context 'when the line doesn\'t match the pattern' do
      it 'return nil' do
        result = described_class.send(:trip_segment, hotel_line)

        expect(result).to be_nil
      end
    end
  end

  describe '.hotel_segment' do
    context 'when hotel line matches the pattern' do
      it 'returns a valid Segment of type Hotel' do
        result = described_class.send(:hotel_segment, hotel_line)

        expect(result).to eq(hotel_segment)
      end
    end

    context 'when the line doesn\'t match the pattern' do
      it 'return nil' do
        result = described_class.send(:hotel_segment, flight_line)

        expect(result).to be_nil
      end
    end
  end
end
