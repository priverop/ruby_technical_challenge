# YARD Inconsistencies Review

## Context

Review of `lib/**/*.rb` after recent changes to identify YARD documentation issues: syntax errors, wrong return types, missing docs, and vague type annotations.

## Issues Found

### Syntax Errors

- `travel_manager.rb:27` — `logger`: `@return [void]>` has a stray `>`
- `travel_manager.rb:37` — `logger=`: same stray `>` issue

### Wrong Return Types

- `travel_manager.rb:~17` — `itinerary`: `@return [void]` should be `@return [String]`
- `segment.rb:19` — `initialize`: `@return [void]` (conventionally omitted or `[Segment]`)

### Type Capitalization

- `itinerary.rb:63` — `validate_based!`: `@param based [STRING]` → should be `[String]`

### Missing YARD Docs

- `parser.rb:~57` — `supported_type?` (private, no docs)
- `parser.rb:~130` — `valid_iata?` (private, no docs)
- `text_formatter.rb:~50` — `supported_type?` (private, no docs)
- `trip.rb:~13` — `initialize` missing `@return`

### Vague Array Types

- `trip_builder.rb:~19` — `build`: `@return [Array]` → `[Array<Trip>]`
- `trip_builder.rb:~68` — `find_link`: `@param unsorted_segments [Array]` → `[Array<Segment>]`
