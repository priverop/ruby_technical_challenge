# frozen_string_literal: true

require_relative 'travel_manager'

## I/O class to manage binary files.
class FileReader
  class << self
    # Reads text from the file.
    #
    # @param file_path [String] path of the user input file.
    # @raise FileEmptyError if the file content is empty.
    # @return [String] content of the file.
    def read(file_path)
      validate_file!(file_path)

      file_content = File.read(file_path)

      raise TravelManager::FileEmptyError, "#{file_path} is empty" if file_content.empty? || file_content.nil?

      file_content
    end

    private

    # Checks if the file is valid.
    #
    # @param file_path [String] path of the file.
    # @raise FileNotFoundError if the path is a directory or doesn't exist.
    # @return [nil, void] nil if validation is ok.
    def validate_file!(file_path)
      raise TravelManager::FileNotFoundError, "#{file_path} is a directory" if Dir.exist?(file_path)
      raise TravelManager::FileNotFoundError, "File #{file_path} not found" unless File.exist?(file_path)
    end
  end
end
