# frozen_string_literal: true

# TODO: include lib folder

# TODO: BASED env

require 'bundler/setup'
require 'debug'
require_relative 'lib/travel_manager'

if ARGV.length != 1
  puts 'Wrong number of arguments. Usage: BASED=SVQ main.rb input.txt'
  exit 0
end

based = ENV.fetch('BASED', nil)

if based.nil? || based.to_s.empty?
  puts 'Please specify where you are based using the BASED env variable. Usage: BASED=SVQ main.rb input.txt'
  exit 0
end

input_reservations = ARGV[0]

puts "Itinerary for user based in #{based}:\n\n"
result = TravelManager.itinerary(input_reservations, based)
puts result
