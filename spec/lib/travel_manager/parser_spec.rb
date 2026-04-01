# frozen_string_literal: true

require 'spec_helper'
require 'travel_manager'
require 'travel_manager/parser'
require 'travel_manager/segment'

RSpec.describe TravelManager::Parser do
  let(:expected_segments) do
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
        expect(result).to match_segments(expected_segments)
      end
    end

    # Just a smaller input, easier to debug
    context 'when input has just one hotel and two flights' do
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
          TravelManager::Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', nil),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', nil)),
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')),
          TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(small_input_reservations)
        expect(result).to match_segments(expected)
      end
    end

    context 'when there is an overnight flight' do
      it 'returns the next day date' do
        input = 'SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 02:00'
        expected = [TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                               datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                               datetime_to: TravelManager::TimeUtils.to_time('2023-01-06', '02:00'))]

        result = described_class.parse(input)
        expect(result).to match_segments(expected)
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
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')),
          TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to match_segments(expected)
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
          TravelManager::Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', nil),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', nil))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to match_segments(expected)
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
          TravelManager::Segment.new(type: 'Train', from: 'BCN', to: 'SVQ',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to match_segments(expected)
      end
    end

    context 'when the input text file has no type' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT: BCN 2023-01-05 -> 2023-01-10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
          SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50
        TEXT
      end

      it 'ignored the hotel line and returns array of flight Segments' do
        expected = [
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')),
          TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to match_segments(expected)
      end
    end

    context 'when the input text file has non supported segment type' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT: Car BCN 2023-01-05 -> 2023-01-10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
          SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50
        TEXT
      end

      it 'ignored the car line and returns array of flight Segments' do
        expected = [
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')),
          TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to match_segments(expected)
      end
    end

    context 'when the input text file has empty segment line' do
      let(:input_reservations) do
        <<~TEXT
          RESERVATION
          SEGMENT:

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
          SEGMENT: Flight BCN 2023-01-10 10:30 -> SVQ 11:50
        TEXT
      end

      it 'ignored the hotel line and returns array of flight Segments' do
        expected = [
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')),
          TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to match_segments(expected)
      end
    end

    context 'when input has Windows OS line endings \r\n' do
      let(:input_reservations) do
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
          TravelManager::Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', nil),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', nil)),
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')),
          TravelManager::Segment.new(type: 'Flight', from: 'BCN', to: 'SVQ',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-10', '10:30'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', '11:50'))
        ]

        result = described_class.parse(input_reservations.gsub("\n", "\r\n"))
        expect(result).to match_segments(expected)
      end
    end

    # rubocop:disable Layout/TrailingWhitespace, Layout/HeredocIndentation
    context 'when input lines have extra spaces' do
      let(:input_reservations) do
        <<~TEXT
              RESERVATION    
            SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10    
        TEXT
      end

      it 'returns array of valid Segments' do
        expected = [
          TravelManager::Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', nil),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-10', nil))
        ]

        result = described_class.parse(input_reservations)
        expect(result).to match_segments(expected)
      end
    end
    # rubocop:enable Layout/TrailingWhitespace, Layout/HeredocIndentation

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

    context 'when the input from has lowercase IATA code' do
      it 'ignores the segment and returns the valid one' do
        input = <<~TEXT
          RESERVATION
          SEGMENT: Flight bcn 2023-01-05 20:40 -> SVQ 22:10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
        TEXT

        expected = [
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10'))
        ]

        result = described_class.parse(input)
        expect(result).to match_segments(expected)
      end
    end

    context 'when destination and arrival are the same' do
      it 'ignores the segment and returns the valid one' do
        input = <<~TEXT
          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> SVQ 22:10

          RESERVATION
          SEGMENT: Flight SVQ 2023-01-05 20:40 -> BCN 22:10
        TEXT

        expected = [
          TravelManager::Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
                                     datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
                                     datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10'))
        ]

        result = described_class.parse(input)
        expect(result).to match_segments(expected)
      end
    end

    context 'when the input has mixed lower/upper IATA codes (from, and to)' do
      it 'ignores the segment' do
        result = described_class.parse('SEGMENT: Flight Bcn 2023-01-05 20:40 -> SVQ 22:10')
        expect(result).to eq([])
      end
    end

    context 'when the input from has a short IATA code' do
      it 'ignores the segment' do
        result = described_class.parse('SEGMENT: Flight SV 2023-01-05 20:40 -> BCN 22:10')
        expect(result).to eq([])
      end
    end

    context 'when the input has lowercase IATA code' do
      it 'ignores the segment' do
        result = described_class.parse('SEGMENT: Flight SVQQ 2023-01-05 20:40 -> BCN 22:10')
        expect(result).to eq([])
      end
    end
  end
end
