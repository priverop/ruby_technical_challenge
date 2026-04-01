# Final Test Strategy

## Context

Synthesized from two analyses: a completeness/QA review (paranoid, exhaustive) and a simplification review (pragmatic, anti-bloat). The goal is a net-positive change: **remove noise, add signal**. The suite should shrink in redundant tests and grow in high-value ones, with a shift toward integration coverage.

Current state: ~35 tests across 6 spec files. Good unit isolation, but unit-heavy / integration-light for a pipeline architecture.

---

## Phase 1: Remove / Simplify (net -6 tests)

These changes reduce noise without losing coverage.

### parser_spec.rb

| Action | Tests | Rationale |
|--------|-------|-----------|
| **Remove** "one hotel and two flights" context (lines 68-96) | -1 | Pure subset of the full-input test. Tests `Array#push` with fewer iterations. |
| **Merge** `"\n"`, `"RESERVATION"`, `"RESERVATION\n\n..."` into one context: "when input has no valid segments" | -2 | All three hit the same code path: `split -> skip RESERVATION -> no regex match`. Keep nil and empty string as distinct (guard clause vs empty split). Merge the rest into one representative case. |

### time_utils_spec.rb

| Action | Tests | Rationale |
|--------|-------|-----------|
| **Remove** "different month returns > 24" (lines 117-125) | -1 | Tests Ruby's `Time` subtraction. The "next day = 24" test already proves the formula works. |
| **Remove** "first date earlier returns negative" (lines 106-115) | -1 | Same -- tests subtraction commutativity. |
| **Remove** "identical times returns 0" (lines 128-136) | -1 | Tests `x - x == 0`. |
| **Keep** "next day same time = 24" and "same day different time = 9" | -- | These two document the contract sufficiently. |

### text_formatter_spec.rb

| Action | Tests | Rationale |
|--------|-------|-----------|
| **Remove** the `[nil]` empty-segments TODO test (lines 75-82) | -1 | Asserts behavior the author doesn't understand. Enshrines confusion as a passing spec. Replace with a real test in Phase 2. |

**Do NOT touch:** `file_reader_spec.rb` (4 clean tests, all distinct), `trip_builder_spec.rb` (every context exercises different linking logic), `travel_manager_spec.rb` validation tests (each hits a different branch).

---

## Phase 2: Add High-Value Tests (net +10 tests)

Prioritized by production risk. Grouped by theme.

### 2A. TripBuilder crash & correctness (3 tests)

These target the most complex module where bugs silently produce wrong output or crash.

| ID | Context | What to assert | Risk addressed |
|----|---------|---------------|----------------|
| **A1** | 3+ flights all <24h apart, chain breaks before a non-connection | `find_trip_destination` calls `.to` on `nil` -> `NoMethodError`. Test should document whether this raises or is handled. | **HIGH** -- unhandled crash in production |
| **A2** | Two trips from `based` that both need the same intermediate segment (e.g. SVQ->BCN on Jan 5 and SVQ->BCN on Mar 2 both want the BCN->SVQ return) | Assert which trip gets the shared segment, verify the other trip is single-segment. Documents the greedy-consumption contract. | **HIGH** -- silent wrong itineraries |
| **A3** | Exactly 24.0 hours gap between two flights | Assert chain breaks (strict `<` boundary). Currently only >24h and <24h are tested. | **MEDIUM** -- off-by-one at connection limit |

### 2B. Integration / end-to-end (3 tests)

The biggest gap. One integration test exists; the pipeline needs more fixture-driven coverage.

| ID | Context | What to assert | Risk addressed |
|----|---------|---------------|----------------|
| **D1** | Enable the commented-out test at `travel_manager_spec.rb:22-31` -- valid IATA code that doesn't match any segment | Raises `TravelManagerError` with the "error building trips" message | **FREE** -- zero-effort coverage for a common user error |
| **D2** | New fixture: input with connection flights (SVQ->BCN->NYC). Full pipeline. | Output groups connections into single trip, correct "TRIP to NYC" header, correct segment ordering | **HIGH** -- no test validates connections survive the full pipeline today |
| **D3** | New fixture: single reservation, single segment | Output is one trip with one segment line. Validates minimal-input formatting. | **MEDIUM** -- edge case in `build_itinerary` join logic |

### 2C. Parser robustness (2 tests)

Input handling at the system boundary -- where real-world data is messy.

| ID | Context | What to assert | Risk addressed |
|----|---------|---------------|----------------|
| **B1** | Input with `\r\n` line endings | Either: segments parse correctly (if code strips `\r`), or test documents that Windows input fails and the fix is tracked | **HIGH** -- `split("\n")` leaves `\r`, breaking all regex `$` anchors. Silent empty parse. |
| **B2** | Segment lines with leading/trailing whitespace | Documents whether whitespace is tolerated or rejected | **MEDIUM** -- copy-paste artifacts silently drop valid segments |

### 2D. Validation & formatter hardening (2 tests)

| ID | Context | What to assert | Risk addressed |
|----|---------|---------------|----------------|
| **C1** | `based` is `nil` | Raises `ArgumentError`. Also verifies error message isn't blank/confusing (currently interpolates to " should be...") | **MEDIUM** -- common caller mistake, poor error message |
| **E1** | `TextFormatter.trips_to_text` with a trip that has empty segments (replacing the removed TODO test) | Decide correct behavior: should return `nil` for that trip, or raise, or skip. Assert the chosen contract explicitly. | **MEDIUM** -- replaces the removed confusion-test with a real decision |

---

## Phase 3: Resolve TODOs

The codebase has 4 TODO comments in tests that represent unresolved design questions. These should be addressed as part of this strategy -- not necessarily by changing behavior, but by making the tests assert the *intended* contract.

| Location | TODO | Recommended action |
|----------|------|-------------------|
| `trip_builder_spec.rb:38` -- "assert everything? decompose?" | The test is fine as-is. It's a comprehensive happy-path test. Remove the TODO comment. | Clean up |
| `trip_builder_spec.rb:111` -- "remove?" (single segment) | Keep. It's the minimal-input case for TripBuilder. It's not redundant. Remove the TODO comment. | Clean up |
| `trip_builder_spec.rb:176` -- "bug or feature?" (same-day round trip destination = SVQ) | Decide. If same-day round trip with destination = base city is correct, add a comment explaining why and remove the TODO. If it's a bug, file it. | Design decision |
| `text_formatter_spec.rb:80` -- "WHY is not nil" | Replaced by test E1 above. The old test gets removed in Phase 1. | Replaced |

---

## Net Result

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Total tests | ~35 | ~39 | +4 |
| Redundant/low-value tests | ~7 | 0 | -7 |
| Integration tests | 1 | 4 | +3 |
| TripBuilder crash/boundary tests | 0 | 3 | +3 |
| Input robustness tests | 0 | 2 | +2 |
| Unresolved TODOs in tests | 4 | 0 | -4 |

**Testing philosophy shift:** fewer unit tests that assert data shapes, more tests that assert *decisions* (linking, connection detection, boundary behavior) and *pipeline correctness* (fixture-driven integration). FileReader and TimeUtils stay lean. TripBuilder and integration get the most attention because that's where the complexity and risk live.

---

## Implementation Order

1. **Phase 1 removals** -- get the noise out first so diffs are clean
2. **D1** -- uncomment and fix the disabled test (free win)
3. **A1** -- all-connections crash (highest severity, likely surfaces a bug to fix)
4. **B1** -- Windows line endings (likely surfaces a bug to fix)
5. **D2** -- connection flights e2e fixture
6. **A2, A3** -- TripBuilder boundary tests
7. **C1, E1, D3, B2** -- remaining hardening
8. **Phase 3 TODO cleanup** -- last, since some TODOs may resolve naturally during implementation

---

## Verification

```bash
bundle exec rspec                    # All tests pass
bundle exec rspec --format doc       # Verify test descriptions read clearly
bundle exec rubocop                  # No style regressions
```

After each phase, run the full suite to confirm no regressions. SimpleCov output should show coverage holding steady or improving -- the removals drop redundant paths, the additions cover new branches.

## Files to modify

- `spec/lib/parser_spec.rb` -- remove 3 tests, add 2
- `spec/lib/time_utils_spec.rb` -- remove 3 tests
- `spec/lib/text_formatter_spec.rb` -- remove 1 test, add 1
- `spec/lib/trip_builder_spec.rb` -- add 3 tests, clean up TODOs
- `spec/lib/travel_manager_spec.rb` -- uncomment 1 test, add 2-3 integration tests
- `spec/fixtures/` -- add 2 new fixture pairs (connection flights, single segment)
