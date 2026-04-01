# frozen_string_literal: true

require 'spec_helper'
require 'travel_manager'
require 'travel_manager/file_reader'

RSpec.describe TravelManager::FileReader do
  let(:fixtures_path) { File.join(File.expand_path('../../', __dir__), 'fixtures') }

  describe '.read' do
    context 'when the file exists' do
      let(:file) { File.join(fixtures_path, 'file_reader.txt') }
      let(:file_content) { 'Testing the file_reader' }

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
        end.to raise_error(TravelManager::FileNotFoundError, 'File unknown.txt not found.')
      end
    end

    context 'when the filename is a directory' do
      let(:directory_path) { 'spec/fixtures/' }

      it 'raises FileNotFoundError' do
        expect do
          described_class.read(directory_path)
        end.to raise_error(TravelManager::FileNotFoundError, 'spec/fixtures/ is a directory.')
      end
    end

    context 'when the file is not readable' do
      let(:file) { File.join(fixtures_path, 'file_reader.txt') }

      before do
        allow(File).to receive(:readable?).with(file).and_return(false)
      end

      it 'raises FileReadError' do
        expect do
          described_class.read(file)
        end.to raise_error(TravelManager::FileReadError, "File #{file} cannot be read.")
      end
    end

    context 'when the file exists but is empty' do
      let(:empty_file) { File.join(fixtures_path, 'empty_file.txt') }

      it 'raises FileEmptyError' do
        expect do
          described_class.read(empty_file)
        end.to raise_error(TravelManager::FileEmptyError, "#{empty_file} is empty.")
      end
    end

    context 'when File.read raises an error' do
      let(:file) { File.join(fixtures_path, 'file_reader.txt') }

      before do
        allow(File).to receive(:read).and_raise(Errno::EACCES.new)
      end

      it 'raises FileReadError' do
        expect do
          described_class.read(file)
        end.to raise_error(TravelManager::FileReadError)
      end
    end
  end
end
