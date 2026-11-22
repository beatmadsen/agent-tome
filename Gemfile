# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# test_helper runs tests in parallel through Active Support. Before 8.1.2 it
# cannot read results back from minitest 6 workers, and `rake` hangs.
gem "activesupport", ">= 8.1.2"

gem "concurrent-ruby", "~> 1.3"
gem "minitest", "~> 6.0"
gem "minitest-mock", "~> 5.27"
gem "rake", "~> 13.0"
