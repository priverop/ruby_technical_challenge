# Requirements Review: Ruby Technical Challenge

## Context
Reviewing the project against `docs/requirements.md` to evaluate whether each requirement is met, identify implicit requirements and over-engineering, and render a hiring verdict.

---

## Explicit Requirements Checklist

### 1. Read input from file `input.txt` and print expected output
**Status: Fully met**

- `main.rb` reads `ARGV[0]` as the file path, delegates to `TravelManager.itinerary`, and `puts` the result.
- Running `BASED=SVQ bundle exec ruby main.rb input.txt` produces output that **exactly matches** the expected output in `docs/requirements.md`.
- Verified by: `spec/fixtures/valid_input.txt` / `valid_output.txt` golden-file test in `itinerary_spec.rb:14-19`.

### 2. BASED env var sets the home airport
**Status: Fully met**

- `main.rb:14` reads `ENV.fetch('BASED', nil)`, validates it, and passes it to the pipeline.
- `TripBuilder.build` filters segments by `segment.from == based` (`trip_builder.rb:21`).
- `Itinerary.validate_based!` validates format (3-letter uppercase) (`itinerary.rb:50-53`).

### 3. Implement sorting and grouping logic for segments
**Status: Fully met**

- `TripBuilder` sorts `based_segments` by `datetime_from` (`trip_builder.rb:22`), then chains linked segments via `find_link` / `sorted_segments`.
- Trips are grouped by starting from the base airport and following the chain of `segment.to == next.from` with a 24h time window.
- Segments within each trip are ordered chronologically by the chaining algorithm.

### 4. Segments won't overlap (assumption)
**Status: Fully met**

- The code does not handle overlapping segments, which aligns with the stated assumption. No unnecessary overlap-detection logic.

### 5. IATA codes are always three-letter uppercase strings
**Status: Fully met**

- `Parser.valid_iata?` (`parser.rb:153-158`) validates length == 3 and uppercase.
- `Itinerary.validate_based!` applies the same rule to the BASED param.
- Parser rejects segments with invalid IATA codes gracefully (logs warning, skips segment).

### 6. Connection flights: less than 24 hours difference
**Status: Fully met**

- `TripBuilder.check_connection?` (`trip_builder.rb:83-91`) checks both segments are flights AND `hours_difference <= 24`.
- `find_trip_destination` skips connection segments to find the real destination (`trip_builder.rb:39-41`).
- The NYC trip correctly shows SVQ->BCN as a connection with BCN->NYC as the destination segment.
- Well-tested: same-day connections, overnight connections, exactly-24h boundary, non-flight connections, multiple consecutive connections.

### 7. Can use external frameworks/libraries
**Status: Fully met**

- Uses RSpec, SimpleCov, RuboCop, YARD, debug gem. All reasonable and standard choices.
- No heavy/unnecessary dependencies for the core logic.

### 8. Can attach notes explaining the solution
**Status: Fully met**

- `docs/decisions.md` is thorough: explains architecture, RESERVATION line handling, connection logic, hotel time modeling, timezone concerns, edge cases, exception vs. logger strategy, Parser responsibility trade-offs.
- `docs/ai.md` transparently documents all AI assistance.
- README has setup instructions with Docker and manual options.

### 9. Solution should be production-ready
**Status: Fully met**

- 65 tests, 0 failures, 99.17% line coverage.
- RuboCop passes with 0 offenses.
- Proper error hierarchy (`TravelManagerError` with specific subclasses).
- Logger for non-fatal issues, exceptions for fatal ones.
- Dockerfile for containerized deployment.
- Handles edge cases: overnight flights, DST transitions, Windows line endings, malformed input, empty files, directories as input.
- `frozen_string_literal: true` on all files.

### 10. Solution should be easy to extend
**Status: Fully met**

- Adding a new segment type (e.g., Bus) requires:
  1. Add constant to `SegmentType`
  2. Add `bus_segment` method to `Parser` (follows `send("#{type.downcase}_segment")` convention)
  3. Add `bus_to_text` method to `TextFormatter` (same `send` pattern)
- `docs/decisions.md` discusses extensibility paths (JsonReader, PDFFormatter, dependency inversion).
- The `send`-based dispatch in Parser and TextFormatter is a smart pattern that auto-discovers new types by method naming convention.

---

## Implicit Requirements (expected but not explicitly stated)

### Code quality and readability
**Fully met.** Clean separation of concerns, descriptive naming, consistent style. The pipeline pattern (Read -> Parse -> Build -> Format) is intuitive. YARD documentation is thorough (possibly excessive, see over-engineering).

### Error handling
**Fully met.** Three-tier approach: CLI messages, Logger warnings for recoverable issues, Exceptions for fatal ones. Custom error hierarchy. Graceful degradation (skips malformed segments, continues processing).

### Testing
**Fully met.** 65 specs covering happy paths, edge cases, boundary conditions, error paths. Custom RSpec matcher (`match_segments`). Golden-file integration test. DST regression tests.

### Documentation
**Fully met.** README with Docker + manual setup, decision record, AI transparency log.

### Runnable out of the box
**Fully met.** `bundle install && BASED=SVQ bundle exec ruby main.rb input.txt` works. Docker alternative provided.

---

## Over-Engineering Assessment

### Minor over-engineering (acceptable)

1. **YARD documentation depth** - Every private method has full `@param`, `@return`, `@raise` annotations. For a project this size, inline comments would suffice. However, the candidate addresses this in `docs/ai.md` (simplified AI-generated docs) and it demonstrates they know the tooling.

2. **Logger infrastructure** - A configurable logger with `TravelManager.logger=` for a CLI tool that processes a single file. A simple `$stderr.puts` would work. But it shows production thinking and the implementation is clean.

3. **Nil guards everywhere** - `TextFormatter` checks `segment.nil?` inside every `*_to_text` method, even though the pipeline guarantees non-nil segments by that point. `trips_to_text` re-checks `trips.nil?` when `Itinerary` already validated this. Defensive, but not harmful.

4. **Docker support** - Nice touch for a take-home, not strictly necessary.

### Not over-engineered (good restraint)

- Did NOT implement dependency injection despite discussing it in decisions.md.
- Did NOT create abstract base classes or interfaces.
- Did NOT add a CLI framework (optparse) - mentioned it as a future improvement.
- Did NOT create a Segment factory or builder pattern.
- Kept the pipeline procedural rather than forcing OOP patterns.

---

## Minor Issues Found

1. **README typo**: `BASED=SVG` should be `BASED=SVQ` in the manual setup section (`README.md:20`).

2. **`find_link` condition**: `segment.datetime_to >= previous.datetime_from` (`trip_builder.rb:72`) - this condition checks that the candidate segment's *end* is after the previous segment's *start*. This is essentially always true for forward-chronological data and doesn't add meaningful filtering. It's a no-op guard that could confuse readers.

3. **`connection?` returns `nil` for non-connections**: `is_connection` is initialized to `nil` rather than `false` (`segment.rb:27`). This means `connection?` returns `nil` (falsy) rather than `false` for segments that haven't been evaluated. Works correctly due to Ruby truthiness, but is semantically imprecise. The tests even assert `is_connection: nil` in some places.

4. **Hotel `from == to`**: Hotels set `to: from` (`parser.rb:124`). This is documented in `decisions.md` and works for the chaining algorithm, but could surprise someone reading the code without that context.

5. **No Segment/Trip specs**: The candidate explicitly chose not to test these (`decisions.md:138`), reasoning they'd just test Ruby. Fair for `Trip` (pure data holder), but `Segment#flight?` and `Segment#connection?` have logic that could warrant a quick spec.

---

## Final Verdict

**Would I move this candidate forward? Yes.**

**Strengths:**
- Correct solution that produces the exact expected output
- Excellent test coverage (65 specs, 99.17% line coverage) with thoughtful edge cases
- Clean architecture with a clear pipeline pattern
- Thorough documentation and decision reasoning
- Good judgment on when NOT to add complexity (resisted over-engineering)
- Handles real-world concerns: overnight flights, DST, Windows line endings, malformed input
- Transparent about AI usage and what was/wasn't delegated
- Shows production mindset: error hierarchy, logging, Docker, linting

**Concerns (minor):**
- The nil-guard pattern is slightly excessive
- `is_connection = nil` vs `false` is a small code smell
- README has a typo in the setup command

These are nitpicks in an otherwise strong submission. The candidate demonstrates solid Ruby fundamentals, good software design judgment, and the ability to reason about trade-offs - exactly what you want to see in a technical challenge.
