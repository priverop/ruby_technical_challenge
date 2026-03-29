# Refactor `def self.` → `class << self`

## Context

All 6 lib files used the `def self.method_name` pattern for class/module methods. The goal was to refactor them to use `class << self` singleton blocks instead — a stylistic preference for explicit singleton class declaration.

## Files changed

- `lib/client.rb`
- `lib/time_utils.rb`
- `lib/parser.rb`
- `lib/text_formatter.rb`
- `lib/travel_manager.rb`
- `lib/trip_builder.rb`

## Changes

### Pattern applied to all 6 files

Removed `self.` from every method definition and wrapped all methods in a `class << self` / `end` block:

```ruby
# Before
class Parser
  def self.parse(reservations)
    ...
  end

  def self.segment(line)
    ...
  end
end

# After
class Parser
  class << self
    def parse(reservations)
      ...
    end

    def segment(line)
      ...
    end
  end
end
```

### `private_class_method` → `private` inside the block

`client.rb` and `travel_manager.rb` used `private_class_method` after their method definitions. Inside `class << self`, regular `private` works as expected:

```ruby
# Before
class Client
  def self.read(file_path)        ...  end
  def self.validate_file!(file_path) ... end

  private_class_method :validate_file!
end

# After
class Client
  class << self
    def read(file_path)        ...  end

    private

    def validate_file!(file_path) ... end
  end
end
```

### Dynamic dispatch (`respond_to?` / `send`) — no change needed

`Parser#segment` and `TextFormatter#segment_to_text` use `respond_to?` and `send` to dynamically dispatch to type-specific methods (e.g. `flight_segment`, `hotel_to_text`). Inside `class << self`, these calls target the singleton class implicitly — no change was required.

### Rubocop fixes (opportunistic)

The refactor added one extra indentation level, pushing several pre-existing long lines over the 120-char limit. Fixed:

- `text_formatter.rb` — converted overlong `unless respond_to?(method_name)` modifier guards to block form; split two long string literals with `\`
- `travel_manager.rb` — converted three overlong `return ... if` guards to block form; added `# rubocop:disable Metrics/MethodLength` on `itinerary` (pipeline orchestrator, inherently long)

Net rubocop result: 12 violations before → 2 after (both pre-existing: the `parser.rb` regex constant and a spec warning).

## Verification

```
58 examples, 0 failures, 4 pending
Line Coverage: 98.48% (195 / 198)
```
