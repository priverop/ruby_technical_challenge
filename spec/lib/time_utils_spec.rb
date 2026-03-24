# frozen_string_literal: true

require 'spec_helper'
require 'time_utils'

RSpec.describe TimeUtils do
  describe '.hours_difference' do
    context 'when next day but same time' do
      it 'returns 24' do
        a = Time.new(2026, 3, 2, 9, 0)
        b = Time.new(2026, 3, 3, 9, 0)

        result = described_class.hours_difference(b, a)

        expect(result).to eq(24)
      end
    end

    context 'when same days but different time' do
      it 'returns value less than 24' do
        a = Time.new(2026, 3, 2, 6, 40)
        b = Time.new(2026, 3, 2, 15, 0)

        result = described_class.hours_difference(b, a)

        expect(result).to be < 24
      end
    end

    context 'when the first date is earlier than the second' do
      it 'returns negative' do
        a = Time.new(2023, 2, 15, 0, 0)
        b = Time.new(2023, 2, 16, 12, 10)

        result = described_class.hours_difference(a, b)

        expect(result).to be < 0
      end
    end

    context 'when same days but different month' do
      it 'returns value bigger than 24' do
        a = Time.new(2026, 3, 2, 9, 0)
        b = Time.new(2026, 4, 2, 9, 0)

        result = described_class.hours_difference(b, a)

        expect(result).to be > 24
      end
    end

    context 'when the dates are the same' do
      it 'returns 0' do
        a = Time.new(2026, 3, 2, 9, 30)
        b = Time.new(2026, 3, 2, 9, 30)

        result = described_class.hours_difference(a, b)

        expect(result).to eq(0)
      end
    end
  end
end
