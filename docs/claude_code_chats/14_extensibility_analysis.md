# Extensibility Analysis

## Context

Evaluation of how easy it would be to extend this travel itinerary project with new features, focusing on architecture quality, SOLID adherence, and concrete extensibility risks.

---

## 1. Architecture Assessment

### What works well

- **Clear linear pipeline**: `FileReader -> Parser -> TripBuilder -> TextFormatter -> Itinerary`. Each stage has a single data transformation responsibility. Easy to follow.
- **Good namespace discipline**: Everything under `TravelManager::`, no global pollution.
- **Segment as a unified model**: Keeps the domain simple for the current scope.
- **Convention-based dispatch** in Parser and TextFormatter (`send("#{type.downcase}_segment")`) provides a lightweight extension point — you add a method and it "just works".

### Modularity, Coupling, Cohesion

| Rating   | Area                                                                                            |
| -------- | ----------------------------------------------------------------------------------------------- |
| Good     | Module isolation — each class in its own file, clear boundaries                                 |
| Good     | Pipeline stages are independent transformations                                                 |
| Moderate | Cohesion within TripBuilder — mixes sorting, linking, connection detection, destination finding |
| Poor     | Parser and TextFormatter must change in lockstep for new segment types (shotgun surgery)        |
| Poor     | TripBuilder mutates Segment objects it doesn't own (stamps `is_connection` externally)          |

---

## 2. Extending with a New Segment Type (e.g., Bus)

This is the most likely extension. Current cost: **changes in 3+ files**, but the convention-based dispatch keeps it manageable.

### Steps required

1. **`segment_type.rb`** — add `BUS = 'Bus'` constant
2. **`parser.rb`** — add `bus_segment` method (delegates to `trip_segment` if format matches Flight/Train, or custom method if format differs)
3. **`text_formatter.rb`** — add `bus_to_text` method

### What makes it harder than it should be

- **Two frozen regex patterns** (`trip_segment_pattern`, `hotel_segment_pattern`) classify all input. A Bus with a different format (e.g., duration instead of arrival time) requires a new regex AND a new parsing method — the existing patterns can't accommodate it.
- **No registry or configuration** — the type list is implicit (whatever methods exist named `*_segment` / `*_to_text`). You discover the supported types by reading code, not by looking at a declaration.
- **Parser line 94**: `from != to` is hardcoded — a round-trip bus would be rejected silently.

---

## 3. Adding a New Output Format (JSON, HTML)

Current cost: **high**. TextFormatter is hardcoded to text output with no abstraction boundary.

- Method names are baked to `*_to_text` (`text_formatter.rb:44`)
- Data extraction (what to show) and presentation (how to format it) are fused in each method
- Adding JSON means either: (a) duplicating the entire class with `*_to_json` methods, or (b) refactoring to separate data extraction from rendering

### Suggested refactor

Extract a `SegmentPresenter` that returns a hash of display-ready values, then let format-specific renderers consume it:

```ruby
# Data extraction (shared)
{ type: "Flight", from: "SVQ", to: "BCN", departure: "2023-03-02 06:40", arrival: "09:10" }

# TextRenderer, JsonRenderer, etc. consume the hash
```

---

## 4. SOLID Violations

### Single Responsibility — TripBuilder has 5 concerns

`trip_builder.rb` mixes: trip assembly, segment sorting/linking, connection detection, destination resolution, and segment mutation. The `sorted_segments` method (line 50-61) simultaneously builds a sorted list AND marks connections via side effects.

### Open/Closed — Parser and TextFormatter

Both require modification to support new segment types. The convention-based dispatch (`send("#{type}_segment")`) is close to being open/closed, but the frozen regex patterns and the need to add methods to existing classes means it's still modification, not extension.

### Dependency Inversion — Itinerary hard-wires everything

`itinerary.rb:24-30` calls `FileReader.read`, `Parser.parse`, `TripBuilder.build`, `TextFormatter.trips_to_text` directly as class methods. No injection, no interfaces. You can't swap any stage without monkey-patching. This makes the orchestrator untestable in isolation and prevents format/parser variations.

### Interface Segregation — Segment's mutable `is_connection`

`segment.rb:10`: `attr_accessor :is_connection` exists solely for TripBuilder to stamp during traversal. Consumers that only read segments are exposed to mutable state they shouldn't need. The flag represents a relationship between two segments, not a property of one.

---

## 5. Key Extensibility Risks

### Risk 1: Shotgun surgery for new segment types
**Impact**: Every new type touches Parser + TextFormatter + SegmentType (+ TripBuilder if it has special linking rules).
**Example**: Adding "Ferry" requires changes in 3 files minimum, with no compile-time or test-time safety net ensuring you didn't miss one.
**Suggested refactor**: Extract a `SegmentDefinition` registry that declares: name, parse pattern, format template, and linking rules in one place. Parser and TextFormatter become generic engines that consult the registry.

### Risk 2: Mutable state coupling via `is_connection`
**Impact**: TripBuilder mutates Segment objects that Parser created. This hidden side effect means the same Segment array can't be safely reused (e.g., building trips with different base airports from the same parsed data would corrupt the connection flags).
**Example**: `trip_builder.rb:57` — `previous.is_connection = check_connection?(previous, next_segment)`.
**Suggested refactor**: Return connection info as a separate data structure (e.g., a wrapper or a hash mapping segment -> connection status), or compute it at format time.

### Risk 3: No output format abstraction
**Impact**: The system can only produce text. Adding JSON/CSV/HTML requires duplicating TextFormatter's structure.
**Example**: `text_formatter.rb:44` — dispatch is `"#{type.downcase}_to_text"`, locking the class to text.
**Suggested refactor**: Strategy pattern — `Formatter` interface with `TextFormatter`, `JsonFormatter` implementations. Itinerary receives the formatter as a parameter.

### Risk 4: Hardcoded temporal/spatial rules
**Impact**: Business rules (24h connection window, IATA-only locations, UTC timezone) are buried in implementation code with no configuration surface.
**Example**: `trip_builder.rb:9` — `CONNECTION_HOURS_LIMIT = 24`; `time_utils.rb` hardcodes UTC.
**Suggested refactor**: Extract these as configurable parameters or policy objects, at least for the connection window.

### Risk 5: Pipeline not injectable
**Impact**: Can't reuse parts of the pipeline independently (e.g., parse a string without reading a file, or format without building trips).
**Example**: `Itinerary.generate` is the only public entry point and it always runs the full pipeline.
**Suggested refactor**: Keep Itinerary as a convenience orchestrator, but ensure each stage remains independently callable (they mostly are already — just make `Itinerary` accept injected dependencies).

---

## 6. What's NOT a problem

- **Segment as a single class** (vs. FlightSegment/TrainSegment subclasses) — for a project this size, a `type` field with convention-based dispatch is simpler than a class hierarchy. Polymorphic subclasses would be premature abstraction here.
- **Static class methods** — Ruby idiom for stateless transformations. Dependency injection would help testability but isn't strictly needed at this scale.
- **Trip as a data container** — it's a value object with no behavior, which is appropriate for its role.

---

## Summary

| Area                         | Extensibility | Main Blocker                                                       |
| ---------------------------- | ------------- | ------------------------------------------------------------------ |
| New segment type             | Moderate      | Shotgun surgery across 3 files; rigid regex patterns               |
| New output format            | Low           | No format abstraction; data and presentation fused                 |
| New linking rules            | Low           | Connection logic embedded in TripBuilder with hardcoded thresholds |
| New input format (XML, JSON) | Low           | Parser is text-line specific; no input format abstraction          |
| Reusing pipeline stages      | Moderate      | Stages are independently callable but Itinerary hard-wires them    |

The architecture is clean for its current scope. The main extensibility investment would be: (1) a segment type registry to eliminate shotgun surgery, (2) separating data extraction from formatting to enable multiple output formats, and (3) making `is_connection` a computed relationship rather than mutable state.
