#!/usr/bin/env ruby
require './buddy.rb'

goto "https://gistpreview.github.io/?1cadf3eb196c23070a53842ab5be0403"
drag_and_drop from: "#drag1", to: "#div1"
assert_js <<~S
!!document.querySelector("#div1").querySelector("#drag1")
S
