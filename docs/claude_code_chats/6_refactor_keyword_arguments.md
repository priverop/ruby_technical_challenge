# Refactor Segment.initialize: remove time_from/time_to, use keyword arguments

## Context

`Segment.initialize` currently accepts `time_from` and `time_to` as separate parameters, then combines them with dates internally via `TimeUtils.to_time`. This leaks parsing concerns into the data model. Additionally, the signature declares keyword arguments but **all callers use positional arguments** — there's already a mismatch.

The goal: Segment receives already-resolved `Time` objects for `datetime_from`/`datetime_to`, and all construction uses keyword arguments.

## Changes

### 1. `lib/segment.rb` — Simplify initialize

Remove `time_from` and `time_to` parameters. `datetime_from` and `datetime_to` become pre-resolved `Time` objects:

```ruby
def initialize(type:, from:, to:, datetime_from:, datetime_to:)
  @type = type
  @from = from
  @to = to
  @datetime_from = datetime_from
  @datetime_to = datetime_to
  @is_connection = false
end
```

Remove `require_relative 'time_utils'` (no longer needed in Segment).

### 2. `lib/parser.rb` — Move TimeUtils.to_time calls into Parser

Add `require_relative 'time_utils'`. Call `TimeUtils.to_time` before constructing Segment, and use keyword arguments:

```ruby
# trip_segment
Segment.new(
  type: type, from: from, to: to,
  datetime_from: TimeUtils.to_time(date_from, time_from),
  datetime_to: TimeUtils.to_time(date_from, time_to)
)

# hotel_segment
Segment.new(
  type: type, from: from, to: from,
  datetime_from: TimeUtils.to_time(date_from, nil),
  datetime_to: TimeUtils.to_time(date_to, nil)
)
```

### 3. Spec files — Update all `Segment.new` calls to keyword arguments with Time objects

Files to update:
- `spec/lib/parser_spec.rb` (3 calls)
- `spec/lib/itinerary_spec.rb` (3 calls)
- `spec/lib/finder_spec.rb` (~18 calls)

Each call changes from:
```ruby
Segment.new('Flight', 'SVQ', 'BCN', '2023-03-02', '2023-03-02', '06:40', '09:10')
```
To:
```ruby
Segment.new(type: 'Flight', from: 'SVQ', to: 'BCN',
            datetime_from: TimeUtils.to_time('2023-03-02', '06:40'),
            datetime_to: TimeUtils.to_time('2023-03-02', '09:10'))
```

Hotels (nil times):
```ruby
Segment.new(type: 'Hotel', from: 'BCN', to: 'BCN',
            datetime_from: TimeUtils.to_time('2023-01-05', nil),
            datetime_to: TimeUtils.to_time('2023-01-10', nil))
```

Ensure `require_relative '../lib/time_utils'` is added where needed (or via spec_helper).

## Verification

```bash
bundle exec rspec
bundle exec rubocop
BASED=SVQ bundle exec ruby main.rb input.txt
```
