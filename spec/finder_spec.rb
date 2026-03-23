# frozen_string_literal: true

require 'spec_helper'
require 'finder'

RSpec.describe Finder do
  describe '.find_links' do
    context 'when' do
      skip 'TBI'
    end
  end

  describe '.sorted_segments' do
    skip 'TBI'
  end

  describe '.find_trip_destiny' do
    let(:with_hotel) do
      [
        Segment.new('Flight', 'SVQ', 'BCN', '2023-01-05', '2023-01-05', '20:40', '22:10'),
        Segment.new('Hotel', 'BCN', 'BCN', '2023-01-05', '2023-01-10', nil, nil),
        Segment.new('Flight', 'BCN', 'SVQ', '2023-01-10', '2023-01-10', '10:30', '11:50')
      ]
    end

    let(:no_hotel) do
      [
        Segment.new('Flight', 'SVQ', 'MAD', '2023-03-02', '2023-03-02', '06:40', '09:10'),
        Segment.new('Flight', 'MAD', 'NYC', '2023-03-02', '2023-03-02', '15:00', '22:45')
      ]
    end

    context 'when no connection flights, and hotel' do
      it 'returns the first destiny' do
        result = described_class.find_trip_destiny(with_hotel)

        expect(result).to be('BCN')
      end
    end

    context 'when no connection flights, and no hotel' do
      it 'returns the first destiny' do
        result = described_class.find_trip_destiny(no_hotel)

        expect(result).to be('MAD')
      end
    end

    context 'when connection flights, and no hotel' do
      it 'returns the first destiny' do
        no_hotel.first.is_connection = true
        result = described_class.find_trip_destiny(no_hotel)

        expect(result).to be('NYC')
      end
    end
  end
end
