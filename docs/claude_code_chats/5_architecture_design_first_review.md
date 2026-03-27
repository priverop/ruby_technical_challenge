# Chat 5: Architecture & Extensibility Brainstorm

## Context
The challenge requirement says "you should provide a solution that is easy to extend." This conversation brainstormed extensibility improvements before implementation.

## Discussion

### User's questions
The user raised six specific points about extensibility:
1. Should BASED be an Object (for future DB storage/validations)?
2. Should segment types use constants instead of hardcoded strings?
3. Modules vs classes, class methods vs instance methods — what to change?
4. Better naming: Parser, Finder, Itinerary — are they descriptive enough?
5. Core vs business logic: Parser and Itinerary are I/O adapters; if company B joins, only those change?
6. Anything else to improve?

### Analysis & Recommendations

#### 1. BASED as Object — Skip
BASED appears in only 3 places: `main.rb` reads it, `TravelManager` validates it, `Finder` compares `segment.from == based`. A `HomeAirport` value object adds a file + spec for a string used 3 times. Risk of appearing over-engineered. Validation is fine in TravelManager.

#### 2. SegmentType Constants — Yes, highest value change
Magic strings (`'Flight'`, `'Train'`, `'Hotel'`) are scattered across `segment.rb`, `parser.rb`, `finder.rb`, `itinerary.rb`, and all specs. A `SegmentType` module with constants provides single source of truth. Adding a new transport type = one constant + one parser method + one formatter method.

```ruby
module SegmentType
  FLIGHT = 'Flight'
  TRAIN  = 'Train'
  HOTEL  = 'Hotel'
  ALL    = [FLIGHT, TRAIN, HOTEL].freeze
end
```

#### 3. Parser type detection — use `send` like Itinerary
The user asked about using `send` in Parser (like Itinerary already does) instead of a case/when. Conclusion: **use `send` in both**. It's more extensible (add a method, it just works), and consistency across the codebase matters for a reviewer. The `send` pattern is already proven in Itinerary's `segment_to_text`.

```ruby
# Parser with send:
type = matcher[1]
method_name = "#{type.downcase}_segment"
send(method_name, line)
```

#### 4. Naming changes

| Current | Proposed | Rationale |
|---------|----------|-----------|
| `Itinerary` | `TextFormatter` | It formats output, doesn't represent an itinerary. Signals pluggability. |
| `Finder` | `TripBuilder` | It assembles trips from segments, doesn't "find" them. |
| `Parser` | Keep | Everyone knows what a parser does. |
| `Trip#destiny` | `Trip#destination` | Standard English. |

#### 5. Core vs Business Logic — Correct instinct

The architecture naturally separates into:
- **Core domain** (format-agnostic): Segment, Trip, TripBuilder, TravelManager
- **I/O adapters** (format-specific): Parser (input), TextFormatter (output)
- **Infrastructure**: Client (file I/O), TimeUtils (utilities)

If "company B" uses different formats, you swap Parser and Formatter. The core domain stays identical.

#### 6. Instance-based formatter — Not needed
The user challenged whether instance-based `formatter.generate()` is actually easier to extend than class-method `TextFormatter.generate()`. Conclusion: **it's the same number of changes either way**. Class methods are simpler and sufficient. The instance approach only matters when a formatter needs state (config options, accumulation), which is hypothetical.

#### 7. Dependency injection in TravelManager — The real extensibility win
The key insight: the pipeline (read → parse → build trips → format) is always the same. What changes per company is **which parser and formatter** are plugged in. TravelManager should be configured, not replaced.

```ruby
module TravelManager
  def self.itinerary(input_file, based, parser: Parser, formatter: TextFormatter)
    validate_based!(based)
    input_reservations = Client.read(input_file)
    unsorted_segments = parser.parse(input_reservations)
    sorted_trips = TripBuilder.find(unsorted_segments, based)
    return 'ERROR!' if sorted_trips.nil?
    sorted_trip_texts = formatter.generate(sorted_trips)
    print_itinerary(sorted_trip_texts)
  end
end
```

Then each company gets its own entry point:

```ruby
# main_company_a.rb
TravelManager.itinerary(input_file, based,
  parser: Parser, formatter: TextFormatter)

# main_company_b.rb
TravelManager.itinerary(input_file, based,
  parser: JsonParser, formatter: HtmlFormatter)
```

#### 8. Namespacing
Currently everything is in a flat global namespace. The discussion considered `lib/travel_manager/companyA/` vs namespacing by role. Conclusion: **namespace by role under `TravelManager::`**, not by company. Company-specific directories couple structure to customers. The DI approach above handles multi-company support without directory restructuring.

#### 9. Segment keyword arguments
The 7-positional-arg constructor has a `rubocop:disable`. Switching to keyword args removes the suppression, is self-documenting, and makes it easier to add fields later.

```ruby
# Before
Segment.new('Flight', 'SVQ', 'BCN', '2023-03-02', '2023-03-02', '06:40', '09:10')

# After
Segment.new(type: SegmentType::FLIGHT, from: 'SVQ', to: 'BCN',
            date_from: '2023-03-02', date_to: '2023-03-02',
            time_from: '06:40', time_to: '09:10')
```

## Implementation Plan

1. **SegmentType constants** + **Parser `send` pattern** (foundational)
2. **Segment keyword arguments** (removes rubocop suppression)
3. **`destiny` → `destination`** (quick fix)
4. **Rename Finder → TripBuilder** (better name)
5. **Rename Itinerary → TextFormatter** (signals pluggability)
6. **DI in TravelManager** (`parser:` and `formatter:` keyword args)

## Files to modify
- `lib/segment_type.rb` — new file
- `lib/segment.rb` — keyword args, SegmentType constant
- `lib/parser.rb` — SegmentType, `send` pattern
- `lib/finder.rb` → `lib/trip_builder.rb` — rename class
- `lib/itinerary.rb` → `lib/text_formatter.rb` — rename class
- `lib/trip.rb` — destiny → destination
- `lib/travel_manager.rb` — update requires, DI params
- All corresponding spec files
