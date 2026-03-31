# frozen_string_literal: true

require 'spec_helper'
require 'travel_manager'

RSpec.describe TravelManager do
  let(:fixtures_path) { File.join(File.expand_path('../', __dir__), 'fixtures') }
  let(:input_file) { File.join(fixtures_path, 'valid_input.txt') }
  let(:output_file) { File.read(File.join(fixtures_path, 'valid_output.txt')) }

  describe '.itinerary' do
    context 'with valid input file and based' do
      it 'returns the right itineraries' do
        based = 'SVQ'

        result = described_class.itinerary(input_file, based)

        expect(result).to match(output_file)
      end
    end

    context 'with valid input file, and based not found' do
      it 'raises TravelManagerError exception' do
        based = 'ASD'

        expect do
          described_class.itinerary(input_file, based)
        end.to raise_error(TravelManager::TravelManagerError, 'there was an error building the trips, please review the input file')
      end
    end

    context 'when the input file has wrong segment type' do
      it 'raises SegmentTypeNotCompatibleError exception' do
        file = File.join(fixtures_path, 'wrong_segment.txt')

        expect do
          described_class.itinerary(file, 'SVQ')
        end.to raise_error(TravelManager::SegmentTypeNotCompatibleError, 'Unknown segment type: BCN')
      end
    end

    context 'when the input file has every line wrong and the parser returns an empty array' do
      it 'raises TravelManagerError exception' do
        file = File.join(fixtures_path, 'wrong_parse.txt')

        expect do
          described_class.itinerary(file, 'SVQ')
        end.to raise_error(TravelManager::TravelManagerError,
                           'there was an error parsing the reservations, please review the input file')
      end
    end

    context 'when the input file has no trips from the based location' do
      it 'raises TravelManagerError exception' do
        file = File.join(fixtures_path, 'valid_input.txt')

        expect do
          described_class.itinerary(file, 'NYC')
        end.to raise_error(TravelManager::TravelManagerError,
                           'there was an error building the trips, please review the input file')
      end
    end

    context 'with empty based' do
      it 'returns exception' do
        based = ''

        expect do
          described_class.itinerary(input_file, based)
        end.to raise_error(TravelManager::ArgumentError, "The based variable (#{based}) should be a three-letter uppercase string.")
      end
    end

    context 'with two letter based' do
      it 'returns exception' do
        based = 'MA'

        expect do
          described_class.itinerary(input_file, based)
        end.to raise_error(TravelManager::ArgumentError, "The based variable (#{based}) should be a three-letter uppercase string.")
      end
    end

    context 'with downcase based' do
      it 'returns exception' do
        based = 'Bcn'

        expect do
          described_class.itinerary(input_file, based)
        end.to raise_error(TravelManager::ArgumentError, "The based variable (#{based}) should be a three-letter uppercase string.")
      end
    end

    context 'with int based' do
      it 'returns exception' do
        based = 123

        expect do
          described_class.itinerary(input_file, based)
        end.to raise_error(TravelManager::ArgumentError, "The based variable (#{based}) should be a three-letter uppercase string.")
      end
    end
  end
end
