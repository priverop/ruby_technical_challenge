# Review: User-Facing Messages

## Context
Audit of all user-facing messages (errors, logs, stdout) across the project for clarity, actionability, consistency, and correct abstraction level.

---

## Inventory

**20 messages total** across 5 files: `main.rb`, `file_reader.rb`, `itinerary.rb`, `parser.rb`, `text_formatter.rb`.

---

## Issues Found

### 1. Clarity / Wording

| #   | File:Line         | Current Message                                                                                                         | Issue                                                                                                                                                                           | Suggested Fix                                                                                                                                         |
| --- | ----------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `main.rb:17-18`   | `"Please specify where you are based using the BASED env variable.Usage: BASED=SVQ bundle exec ruby main.rb input.txt"` | **Missing space** between sentences — the string concatenation `'..variable.' \ 'Usage:...'` produces `variable.Usage:` with no space.                                          | Add a space: `"...env variable. Usage: BASED=SVQ..."`                                                                                                 |
| 2   | `main.rb:10`      | `"Wrong number of arguments. Usage: BASED=SVQ main.rb input.txt"`                                                       | Usage example is inconsistent with line 18 — missing `bundle exec ruby` prefix. A user running `ruby main.rb` won't match this pattern.                                         | Unify both usage strings. Either always show `BASED=SVQ bundle exec ruby main.rb input.txt` or always show the short form.                            |
| 3   | `main.rb:30`      | `"There was an error during the process: #{e.message}"`                                                                 | "during the process" is vague. The user doesn't know what "process" is. Also, wrapping already-clear exception messages adds noise without value.                               | `"Error: #{e.message}"` — keep it short, the inner message already explains the problem.                                                              |
| 4   | `itinerary.rb:67` | `"#{input_file} could not be parsed. Please review the logs."`                                                          | "Please review the logs" assumes the user knows logs exist and where they go (stderr via Logger). Most CLI users won't think of stderr as "logs."                               | `"No valid segments found in #{input_file}. Check the file format and warnings above."` — points to visible stderr warnings the parser already emits. |
| 5   | `itinerary.rb:92` | `"Trips could not be formatted. Please review the logs."`                                                               | Same "review the logs" issue. Also, this error is nearly unreachable (would require all segments to be of an unknown type after parsing succeeded).                             | `"Trips could not be formatted. Check warnings above for details."`                                                                                   |
| 6   | `parser.rb:89`    | Expected format hint: `'SEGMENT: Type FROM DATE TIME -> TO TIME'`                                                       | Good idea, but uses placeholder names (`Type`, `FROM`, `TO`) that don't match the actual keywords. `FROM`/`TO` could be confused with the literal words rather than IATA codes. | `'SEGMENT: <Type> <IATA> <YYYY-MM-DD> <HH:MM> -> <IATA> <HH:MM>'`                                                                                     |
| 7   | `parser.rb:114`   | Expected format hint for Hotel: `'SEGMENT: Hotel FROM DEPARTURE_DATE -> TO'`                                            | `TO` here means checkout date, not a location. `DEPARTURE_DATE` is unusual for a hotel (check-in is the standard term).                                                         | `'SEGMENT: Hotel <IATA> <CHECK_IN_DATE> -> <CHECK_OUT_DATE>'`                                                                                         |

### 2. Consistency

| #   | File:Line                                      | Issue                                                                                                                                                                                                                                                                                                                                                                         |
| --- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 8   | `file_reader.rb:48-50`                         | Inconsistent sentence structure: `"#{file_path} is a directory."` vs `"File #{file_path} not found."` vs `"File #{file_path} cannot be read."` — the first omits the "File" prefix.                                                                                                                                                                                           |
| 9   | `parser.rb:17-20` vs `text_formatter.rb:53-55` | The parser and formatter both warn about unknown segment types, but use different wording. Parser: `"Parsed type '%s' is not a known Segment type. Ignoring line '%s'."` / Formatter: `"Parsed type '%s' is not a known Segment type and cannot be formatted to text. Ignoring segment '%s %s -> %s'"`. The prefix "Parsed type" is odd for the formatter (it's not parsing). |
| 10  | `itinerary.rb:53`                              | Uses `TravelManager::ArgumentError` but the message says "The based variable" — internal variable name leaking. Users don't know what "the based variable" means in context.                                                                                                                                                                                                  |

### 3. Actionability

| #   | File:Line         | Issue                                                                                   | Suggested Fix                                                                                                                                                                                                                                                                                                                                       |
| --- | ----------------- | --------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 11  | `itinerary.rb:80` | `"No segments from #{based} found."`                                                    | Doesn't tell the user what to do. Suggest: `"No trips starting from #{based} found. Verify that BASED matches an origin in your input file."`                                                                                                                                                                                                       |
| 12  | `itinerary.rb:53` | `"The based variable (#{based}) should be a three-letter uppercase string."`            | Good validation, but could hint at the fix. Suggest: `"Invalid base location '#{based}'. Must be a 3-letter IATA code (e.g., SVQ)."`                                                                                                                                                                                                                |
| 13  | `parser.rb:20`    | `"Parsed location '%s' is not a valid IATA code: it should be three-letter uppercase."` | Silently ignored — the segment is dropped with only a log warning. If the input file has a systematic issue (e.g., lowercase codes), all segments are silently discarded and the user gets "could not be parsed" with no direct explanation. This is acceptable as-is since the parser already emits a warning per bad line, but it's worth noting. |

### 4. Silent Failures / Missing Messages

| #   | Location               | Issue                                                                                                                                                                                                        |
| --- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 14  | `parser.rb:94`         | `from != to` check silently drops segments where origin equals destination (e.g., `SEGMENT: Flight SVQ 2023-03-02 06:40 -> SVQ 09:10`). No warning is logged — the segment vanishes.                         |
| 15  | `trip_builder.rb:24`   | Returns `nil` when no based segments are found — no logging. The caller (`itinerary.rb:80`) raises, but by then the context of *why* (no segments match the base) is lost. A debug/warn log here would help. |
| 16  | `text_formatter.rb:16` | If all trips filter to `nil` (every trip has only unknown segment types), returns `nil` silently. The caller raises `"Trips could not be formatted"` but the root cause (all unknown types) isn't surfaced.  |

### 5. Abstraction Level

| #   | Location            | Issue                                                                                                                                                                                                                                                                                                           |
| --- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 17  | `file_reader.rb:35` | `rescue Errno::ENOENT, Errno::EACCES => e` re-raises with `e.message` — this can leak OS-level error strings like `"No such file or directory @ rb_sysopen - /path"`. The validate_file_path! above should catch these cases first, so this is a fallback, but the raw Ruby error message is not user-friendly. |
| 18  | `main.rb:24`        | `"Itinerary for user based in #{based}:\n\n"` is printed **before** the itinerary is generated. If the process fails, the user sees the header followed by an error — misleading partial output.                                                                                                                |

---

## Summary of Recommendations (Priority Order)

1. **Fix the missing space bug** in `main.rb:17-18` (actual bug)
2. **Move the header print** (`main.rb:24`) inside the success path, after `result` is generated
3. **Unify usage strings** in `main.rb` (lines 10 and 18)
4. **Replace "Please review the logs"** with "Check warnings above" in `itinerary.rb`
5. **Improve BASED validation message** to say "IATA code" with an example
6. **Add a warning** in `parser.rb` when `from == to` silently drops a segment
7. **Normalize file_reader error prefixes** (always include "File" or never)
8. **Shorten the generic error wrapper** in `main.rb:30` to `"Error: #{e.message}"`
9. **Fix expected format hints** in parser to use angle-bracket placeholders
10. **Align unknown-type warnings** between parser and formatter

---

## Verification
- `bundle exec rspec` — all tests should still pass (message changes may require spec updates for tests that assert on exact error strings)
- `BASED=SVQ bundle exec ruby main.rb input.txt` — check normal output
- `BASED=svq bundle exec ruby main.rb input.txt` — check improved BASED validation message
- `bundle exec ruby main.rb` — check usage message
- `bundle exec ruby main.rb nonexistent.txt` — check file error
