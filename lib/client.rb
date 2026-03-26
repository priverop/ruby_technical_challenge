# frozen_string_literal: true

require_relative 'travel_manager'

## I/O functionallity
class Client
  def self.read(filename)
    validate_file!(filename)

    File.read(filename)
  end

  def self.validate_file!(filename)
    raise TravelManager::FileNotFoundError, "#{filename} is a directory" if Dir.exist?(filename)
    raise TravelManager::FileNotFoundError, "File #{filename} not found" unless File.exist?(filename)
  end

  private_class_method :validate_file!
end
