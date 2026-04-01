# frozen_string_literal: true

require 'spec_helper'
require 'travel_manager'
require 'travel_manager/itinerary'

RSpec.describe TravelManager::Itinerary do
  let(:fixtures_path) { File.join(File.expand_path('../../', __dir__), 'fixtures') }
  let(:input_file) { File.join(fixtures_path, 'valid_input.txt') }
  let(:output_file) { File.read(File.join(fixtures_path, 'valid_output.txt')) }

  describe '.generate' do
    context 'with valid input file and based' do
      it 'returns the right itineraries' do
        based = 'SVQ'

        result = described_class.generate(input_file, based)

        expect(result).to match(output_file)
      end
    end

    context 'with valid input file, and based not found' do
      it 'raises TravelManagerError exception' do
        based = 'ASD'

        expect do
          described_class.generate(input_file, based)
        end.to raise_error(TravelManager::TravelManagerError,
                           'No segments from ASD found. Verify that BASED matches an origin in your input file.')
      end
    end

    context 'when the input file has every line wrong and the parser returns an empty array' do
      it 'raises TravelManagerError exception' do
        file = File.join(fixtures_path, 'wrong_parse.txt')

        expect do
          described_class.generate(file, 'SVQ')
        end.to raise_error(TravelManager::TravelManagerError,
                           "#{file} could not be parsed. Please review the warnings above.")
      end
    end

    context 'when the input file has no trips from the based location' do
      it 'raises TravelManagerError exception' do
        file = File.join(fixtures_path, 'valid_input.txt')

        expect do
          described_class.generate(file, 'NYC')
        end.to raise_error(TravelManager::TravelManagerError,
                           'No segments from NYC found. Verify that BASED matches an origin in your input file.')
      end
    end

    # When adding a new Segment type, we need to create new methods in the Parser and TextFormatter.
    # If only added in the Parser, the segment will be parsed but we won't be able to format it later.
    # Resulting on an empty array as TextFormatter.trips_to_text output.
    context 'when the input file has an unknown segment type for the TextFormatter' do
      it 'raises TravelManagerError exception' do
        file = File.join(fixtures_path, 'new_segment_type.txt')
        car_segment = TravelManager::Segment.new(
          type: 'Car', from: 'SVQ', to: 'BCN',
          datetime_from: TravelManager::TimeUtils.to_time('2023-01-05', '20:40'),
          datetime_to: TravelManager::TimeUtils.to_time('2023-01-05', '22:10')
        )
        allow(TravelManager::Parser).to receive(:parse).and_return([car_segment])
        allow(TravelManager::TripBuilder).to receive(:build).and_return(
          [TravelManager::Trip.new('BCN', [car_segment])]
        )

        expect do
          described_class.generate(file, 'SVQ')
        end.to raise_error(TravelManager::TravelManagerError,
                           'Trips could not be formatted. Please review the warnings above.')
      end
    end

    context 'with empty based' do
      it 'returns exception' do
        based = ''

        expect do
          described_class.generate(input_file, based)
        end.to raise_error(TravelManager::BasedArgumentError,
                           "Invalid BASED '#{based}'. Must be a 3-letter uppercase IATA code (e.g., BCN).")
      end
    end

    context 'with two letter based' do
      it 'returns exception' do
        based = 'MA'

        expect do
          described_class.generate(input_file, based)
        end.to raise_error(TravelManager::BasedArgumentError,
                           "Invalid BASED '#{based}'. Must be a 3-letter uppercase IATA code (e.g., BCN).")
      end
    end

    context 'with downcase based' do
      it 'returns exception' do
        based = 'Bcn'

        expect do
          described_class.generate(input_file, based)
        end.to raise_error(TravelManager::BasedArgumentError,
                           "Invalid BASED '#{based}'. Must be a 3-letter uppercase IATA code (e.g., BCN).")
      end
    end

    context 'with int based' do
      it 'returns exception' do
        based = 123

        expect do
          described_class.generate(input_file, based)
        end.to raise_error(TravelManager::BasedArgumentError,
                           "Invalid BASED '#{based}'. Must be a 3-letter uppercase IATA code (e.g., BCN).")
      end
    end
  end
end
