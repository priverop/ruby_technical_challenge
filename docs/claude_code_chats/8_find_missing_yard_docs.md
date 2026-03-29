# Find missing YARD documentation

## Context

The codebase had YARD documentation added incrementally across several sessions. This session was a diagnostic to locate the remaining gaps — the user knew 3 classes and 1 method were missing docs but couldn't pinpoint them.

## Findings

### 3 classes with missing YARD

**`lib/segment.rb` — `Segment`**
All instance methods lack YARD docs: `initialize`, `attributes`, `flight?`, `connection?`, `==`.

**`lib/trip.rb` — `Trip`**
`initialize` has no YARD docs.

**`lib/parser.rb` — `Parser`**
`Parser#segment` raises `TravelManager::SegmentTypeNotCompatibleError` but has no `@raise` tag. `TextFormatter#segment_to_text` documents the same pattern consistently with `@raise`.

### 1 method with incomplete YARD

**`lib/trip_builder.rb` — `TripBuilder#build`**
`@return` and `@param based` contain unfilled YARD generator placeholders:

```ruby
# @param based [String] .
# @return [<Type>] <description>
```

Should be:

```ruby
# @param based [String] starting IATA location code (the BASED env var).
# @return [Array<Trip>, nil] ordered trips starting from +based+, or nil if no segments originate there.
```

## What was ruled out

- `SegmentType` constants — user confirmed these do not need YARD docs.
