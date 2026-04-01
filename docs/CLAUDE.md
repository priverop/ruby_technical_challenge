# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install                              # Install dependencies
bundle exec rspec                           # Run all tests
bundle exec rspec spec/lib/travel_manager/itinerary_spec.rb  # Run a single spec file
bundle exec rubocop                         # Lint
bundle exec rubocop -a                      # Lint with auto-fix
BASED=SVQ bundle exec ruby main.rb input.txt   # Run the application
```

## Architecture

This is a travel itinerary generator that transforms raw reservations into organized trip summaries. Ruby 3.4+.

All classes are namespaced under `TravelManager::`.

**Pipeline:**
```
Input File → FileReader → Parser → TripBuilder → TextFormatter → (assembled by Itinerary)
```

| Class | File | Role |
|-------|------|------|
| `TravelManager` | `lib/travel_manager.rb` | Facade module; delegates to `Itinerary.generate`, defines error classes |
| `FileReader` | `lib/travel_manager/file_reader.rb` | File I/O and input validation |
| `Parser` | `lib/travel_manager/parser.rb` | Parses text lines into `Segment` objects via regex |
| `Segment` | `lib/travel_manager/segment.rb` | Data model for a single travel leg |
| `SegmentType` | `lib/travel_manager/segment_type.rb` | Constants for segment types (Flight, Train, Hotel) |
| `TripBuilder` | `lib/travel_manager/trip_builder.rb` | Groups segments into trips by chaining them chronologically |
| `Trip` | `lib/travel_manager/trip.rb` | Container for a destination and its ordered segments |
| `Itinerary` | `lib/travel_manager/itinerary.rb` | Orchestrates the full pipeline: read → parse → build → format |
| `TextFormatter` | `lib/travel_manager/text_formatter.rb` | Formats Trip/Segment objects into final text output |
| `TimeUtils` | `lib/travel_manager/time_utils.rb` | Date/time parsing, formatting, and comparison helpers |

**Input format:** Lines of `RESERVATION` headers followed by `SEGMENT:` lines in two formats:
- Trip: `SEGMENT: Flight SVQ 2023-03-02 06:40 -> BCN 09:10` (type, from, date, time → to, time)
- Hotel: `SEGMENT: Hotel BCN 2023-01-05 -> 2023-01-10` (type, location, check-in → check-out, no times)

**Key behaviors:**
- `BASED` env var sets the home airport (IATA code). The trip builder starts chains from segments originating there.
- Segments chain when `segment.to == next.from` AND departure is within 24h of previous arrival (or same date for hotels with 00:00 times).
- **Connection flights:** Two consecutive flights on the same day with <24h gap are marked as connections (e.g., SVQ→BCN→NYC becomes one trip to NYC, with SVQ→BCN as a connection).
- Trip destination = the `.to` of the first non-connection segment.
- Spec fixtures at `spec/fixtures/` define the canonical input/output contract.
