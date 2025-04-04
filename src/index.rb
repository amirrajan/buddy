#!/usr/bin/env ruby
require './buddy.rb'

goto "http://lefthandedgoat.github.io/canopy/testpages/"
with_timeout 0 do
  find_text "Test Field 1"
  find_text "test value 1"
end

click "#testfield1"
set_value "#testfield1", "new value"
find_text "new value", timeout: 0
find_input_with_value "new value"

reload_browser
assert_element_inner_text "#ajax", "ajax loaded"

reload_browser
assert_element_inner_text "#slowAjax", "slow ajax loaded", timeout: 10

reload_browser
click "#ajax_button", timeout: 5

assert_element "#ajax_button_clicked",
               callback: lambda { |element| element.inner_text == "ajax button clicked" }

reload_browser
click "#item_list"
type "item 3"
click "#item_list"
assert_element_value "#item_list", 3

set_value "#item_list", 1
assert_element_value "#item_list", 1
