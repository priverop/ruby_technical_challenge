# frozen_string_literal: true

# TODO: include lib folder

# TODO: BASED env

require 'bundler/setup'
require 'debug'
require_relative 'lib/travel_manager'

if ARGV.length != 1
  puts 'Wrong number of arguments. Usage: main.rb input.txt'
  exit 0
end

input_reservations = ARGV[0]

result = TravelManager.itinerary(input_reservations)

pp result