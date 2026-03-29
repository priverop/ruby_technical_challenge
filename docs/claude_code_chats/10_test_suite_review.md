# Test Suite Review

## Context

Two-pass review of the test suite acting as (1) a senior QA engineer evaluating completeness, then (2) a pragmatic senior engineer evaluating overengineering. The goal was to produce a balanced final test strategy.

## Analysis 1: QA Coverage Review

### Coverage gaps found

| Gap | Severity |
|---|---|
| **Segment** — no dedicated spec. `==`, `flight?`, `connection?` untested in isolation | Medium |
| **Trip** — no dedicated spec | Low |
| **main.rb** — no spec at all | Medium |
| **TimeUtils** — 5 of 8 public methods untested (`to_time`, `date_to_time`, `datetime_to_time`, `same_dates?`, formatters) | High |
| **TextFormatter** — `trip_to_text` happy-path test is SKIPPED | Medium |
| **TextFormatter** — over-mocking in `segment_to_text`, `flight_to_text`, `train_to_text` | Medium |

### Critical risks identified

1. **Infinite loop in TripBuilder** — `find_link` searches full `unsorted_segments` on every iteration (never consumed). Same-day round trips (SVQ→BCN morning, BCN→SVQ evening) create an endless chain.
2. **NoMethodError crash** — `find_trip_destination` calls `.to` on nil when all segments are connections.
3. **Overnight flight corruption** — Parser uses departure date for arrival time. A 23:00→02:00 flight gets `datetime_to < datetime_from`.

### Other risks

- Segment reuse across trips (duplicate output)
- Negative `hours_difference` passes `check_connection`
- Unhandled `SegmentTypeNotCompatibleError` propagation through TravelManager
- Trailing whitespace silently drops segments (regex `$` anchor)
- `main.rb` exits with code 0 on errors

## Analysis 2: Simplification Review

### Overengineering found

- **24 tests coupled to private methods via `send`** across Parser, TripBuilder, and TextFormatter
- **8 private method tests in Parser** (`.segment`, `.trip_segment`, `.hotel_segment`) — all redundant with `.parse` tests
- **3 redundant empty-input Parser tests** — `"\n"`, `'RESERVATION'`, `"RESERVATION \n\n..."` all hit the same code path as empty string
- **6 mocked/dead TextFormatter tests** — mocked dispatch tests prove Ruby's `send` works, not that formatting is correct; one test skipped/dead
- **TripBuilder private method tests** (14 tests) add diagnostic value but break on any rename/extract refactor

### Tests that should not be touched

- Parser `.parse` with valid/malformed inputs
- FileReader all 4 tests
- TripBuilder `.build` 3 tests
- TextFormatter `.trips_to_text` valid + empty, `.hotel_to_text`, `.travel_to_text`, unknown type error
- TravelManager all 6 tests
- TimeUtils all 5 tests

## Final Strategy

### Principle

Test public contracts, not internal wiring. Test surface per module: `.parse`, `.build`, `.trips_to_text`, `.read`, `.itinerary`.

### Phase 1: Remove noise (-17 tests)

- Parser: delete `.segment`, `.trip_segment`, `.hotel_segment` blocks (8 tests) + 3 redundant empty-input variants
- TextFormatter: delete 3 mocked dispatch tests + 2 mocked `flight/train_to_text` + 1 skipped dead test

### Phase 2: Refactor TripBuilder tests (-14, +6)

Replace 14 `send(:private_method)` tests with 6 scenario-driven `.build` tests:
- Connection flight detection (replaces `check_connection` + `find_trip_destination`)
- No connection with hotel between flights
- Cross-day linking within 24h (replaces `find_link` <24h)
- No link when gap >24h (replaces `find_link` >24h)
- Same-date hotel linking (replaces `find_link` same-date)
- Single segment, no continuation (replaces `sorted_segments` empty)

### Phase 3: Add real coverage (+8 tests)

**Critical:**
- TripBuilder: same-day round trip does not infinite loop
- Parser: overnight flight handling (document intended behavior)

**High:**
- TravelManager: `SegmentTypeNotCompatibleError` propagation
- TextFormatter: unknown type through public API (replaces `send`-based version)

**Medium:**
- TimeUtils: `same_dates?`, `to_time`, formatting methods

### Net result

| Phase | Removed | Added | Net |
|---|---|---|---|
| Remove noise | -17 | 0 | -17 |
| Refactor TripBuilder | -14 | +6 | -8 |
| Add real coverage | 0 | +8 | +8 |
| **Total** | **-31** | **+14** | **-17** |

~42 tests → ~25 tests. Zero `send` calls. Higher real confidence.
