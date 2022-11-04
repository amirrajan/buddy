#!/usr/bin/env ruby
require './buddy.rb'

goto "http://lefthandedgoat.github.io/canopy/testpages/autocomplete.html"
click "#search"
assert_element_contains_inner_text "body", "Jane Doe"
