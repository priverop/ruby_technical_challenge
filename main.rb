# frozen_string_literal: true

require 'bundler/setup'
require_relative 'lib/travel_manager'

if ARGV.length != 1
  warn 'Wrong number of arguments. Usage: BASED=SVQ main.rb input.txt'
  exit 0
end

based = ENV.fetch('BASED', nil)

if based.nil? || based.to_s.empty?
  warn 'Please specify where you are based using the BASED env variable. Usage: BASED=SVQ main.rb input.txt'
  exit 1
end

input_reservations = ARGV[0]

puts "Itinerary for user based in #{based}:\n\n"
begin
  result = TravelManager.itinerary(file: input_reservations, based: based)
  puts result
  exit 0
rescue TravelManager::TravelManagerError => e
  warn "There was an error during the process: #{e.message}"
  exit 1
end
