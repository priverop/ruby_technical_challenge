# frozen_string_literal: true

require 'spec_helper'
require 'client'

RSpec.describe Client do
  let(:fixtures_path) { File.join(File.expand_path('../', __dir__), 'fixtures') }

  describe '.read' do
    context 'when the file exists' do
      let(:file) { File.join(fixtures_path, 'client.txt') }
      let(:file_content) { 'Testing the client' }

      it 'returns the file content' do
        result = described_class.read(file)
        expect(result).to eq(file_content)
      end
    end

    context 'when the file does not exist' do
      let(:file) { 'unknown.txt' }

      it 'raises FileNotFoundError' do
        expect do
          described_class.read(file)
        end.to raise_error(TravelManager::FileNotFoundError, 'File unknown.txt not found')
      end
    end

    context 'when the filename is a directory' do
      let(:directory_path) { 'spec/fixtures/' }

      it 'raises FileNotFoundError' do
        expect do
          described_class.read(directory_path)
        end.to raise_error(TravelManager::FileNotFoundError, 'spec/fixtures/ is a directory')
      end
    end
  end
end
