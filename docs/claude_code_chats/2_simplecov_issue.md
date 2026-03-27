# Fix SimpleCov to cover the whole lib/ folder

## Context
SimpleCov only reports coverage for files that are `require`d during the test run. Currently only `finder.rb` and `time_utils.rb` (and their transitive dependencies) are required by specs, so the other 6 lib files are invisible to the coverage report.

## Change
**File:** `spec/spec_helper.rb`

Replace:
```ruby
SimpleCov.start 'exclude_spec_files'
```

With:
```ruby
SimpleCov.start 'exclude_spec_files' do
  track_files 'lib/**/*.rb'
end
```

This tells SimpleCov to include all `lib/**/*.rb` files in the report even if they were never loaded, showing them at 0% coverage.

## Verification
```bash
bundle exec rspec
```
Then check `coverage/index.html` — all 8 lib files should appear in the report.
