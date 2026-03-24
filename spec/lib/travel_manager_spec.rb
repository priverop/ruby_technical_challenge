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

    context 'with valid input file, and wrong based' do
      it 'returns ERROR message' do
        based = 'SVG'

        result = described_class.itinerary(input_file, based)

        expect(result).to eq('ERROR!')
      end
    end
  end
end
