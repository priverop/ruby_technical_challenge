# frozen_string_literal: true

module TravelManager
  ## I/O class to manage binary files.
  class FileReader
    class << self
      # Reads text from the file.
      #
      # @param file_path [String] path of the user input file.
      # @raise [FileEmptyError] if the file content is empty.
      # @return [String] content of the file.
      def read(file_path)
        validate_file_path!(file_path)
        content = read_file!(file_path)
        validate_content!(content, file_path)

        content
      end

      private

      #
      # Reads the file safely.
      # There are multiple reasons for File.read to fail, and to avoid race conditions
      # I'd rather rescue any system call error.
      #
      # @param file_path [String] path of the file.
      #
      # @raise [FileReadError] if there is any non controller exception.
      #
      # @return [String] contents of the file.
      #
      def read_file!(file_path)
        File.read(file_path)
      rescue SystemCallError => e
        raise TravelManager::FileReadError, e.message
      end

      #
      # Checks if the file is a valid file that we can read.
      #
      # @param file_path [String] path of the file.
      #
      # @raise [FileNotFoundError] if the path is a directory or doesn't exist.
      # @raise [FileReadError] if the file is not readable.
      #
      # @return [nil, void] nil if validations are ok.
      def validate_file_path!(file_path)
        raise TravelManager::FileNotFoundError, "File #{file_path} is a directory." if Dir.exist?(file_path)
        raise TravelManager::FileNotFoundError, "File #{file_path} not found." unless File.exist?(file_path)
        raise TravelManager::FileReadError, "File #{file_path} cannot be read." unless File.readable?(file_path)
      end

      #
      # Checks if the file content (after read) is empty.
      #
      # @param file_content [String] content of the file.
      # @param file_path [String] file path.
      #
      # @raise [FileEmptyError] if the file content is empty or nil.
      #
      # @return [void, nil] nil if validations are ok.
      #
      def validate_content!(file_content, file_path)
        raise TravelManager::FileEmptyError, "#{file_path} is empty." if file_content.empty?
      end
    end
  end
end
