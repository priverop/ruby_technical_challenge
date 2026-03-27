# Chat 3: `send` method approach and `segment_to_text` unit test

## Discussion

### User's question
The `Itinerary` class uses `send` in `segment_to_text` to dynamically dispatch to `flight_to_text`, `train_to_text`, or `hotel_to_text` based on `segment.type.downcase`. The user asked:
1. Is this overengineered vs a simple `case`?
2. How to unit test the routing in `segment_to_text`?

### Analysis: `send` vs alternatives

For **scalability** (adding new segment types like "Car" with minimal edits), `send` is the best choice:

- **`send`**: Add new type -> just add the method. Done. The naming convention *is* the routing.
- **Hash lookup**: Add new type -> add the method AND update the hash. Two places to edit.
- **Case**: Add new type -> add the method AND add a branch. Two places to edit.

**Recommendation**: Keep `send`, but add a `respond_to?` guard so that a missing method gives a clear error instead of a cryptic `NoMethodError`.

### Suggested guard for `segment_to_text`

```ruby
def self.segment_to_text(segment)
  return if segment.nil?

  method_name = "#{segment.type.downcase}_to_text"
  raise ArgumentError, "Unknown segment type: #{segment.type}" unless respond_to?(method_name)

  send(method_name, segment)
end
```

This way, if someone adds "Car" to the Parser but forgets `car_to_text`, they get a helpful error pointing at the problem.

### Testing the routing

Since `segment_to_text` is a router, the unit test should verify it **delegates to the right formatter** — not test the formatting itself (already covered by other tests).

Use `expect(...).to receive(...)` (message expectation) on the **type-specific** method, not `allow`:

```ruby
describe '.segment_to_text' do
  context 'when the segment is type Flight' do
    it 'delegates to flight_to_text' do
      expect(described_class).to receive(:flight_to_text).with(flight_segment).and_return(flight_travel_text)

      result = described_class.segment_to_text(flight_segment)
      expect(result).to eq(flight_travel_text)
    end
  end

  context 'when the segment is type Train' do
    it 'delegates to train_to_text' do
      expect(described_class).to receive(:train_to_text).with(train_segment).and_return(train_travel_text)

      result = described_class.segment_to_text(train_segment)
      expect(result).to eq(train_travel_text)
    end
  end

  context 'when the segment is type Hotel' do
    it 'delegates to hotel_to_text' do
      expect(described_class).to receive(:hotel_to_text).with(hotel_segment).and_return(hotel_text)

      result = described_class.segment_to_text(hotel_segment)
      expect(result).to eq(hotel_text)
    end
  end
end
```

Key difference from the original attempt: use `expect` (not `allow`) on the **type-specific** method (`flight_to_text`) rather than `travel_to_text`. This verifies routing — that `send` dispatched to the correct method based on segment type.

---

## Plan

### 1. Add `respond_to?` guard to `segment_to_text`
**File:** `lib/itinerary.rb:25-28`

### 2. Replace the skipped test with routing tests
**File:** `spec/lib/itinerary_spec.rb:18-27`

Replace the current `segment_to_text` describe block with tests for all 3 types, verifying delegation via `expect(described_class).to receive(:type_to_text)`.

### Verification
```bash
bundle exec rspec spec/lib/itinerary_spec.rb
```
