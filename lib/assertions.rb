require 'ferrum'

module Buddy
  def assert_element selector, callback:, failure: nil, timeout: default_timeout
    assertion_current_timeout = 0
    found_element = nil
    assertion_passed = false

    while !assertion_passed && assertion_current_timeout <= timeout
      found_element = element_or_nil selector, timeout: 0
      if found_element
        assertion_passed = callback.call found_element
      end

      assertion_current_timeout += 0.1
      sleep 0.1
    end

    if !assertion_passed && failure
      failure.call found_element
    elsif !assertion_passed
      if !found_element
        raise <<~S
        * ASSERTION FAILED - assert_element
          Element with selector #{selector} was not found.
        S
      else
        raise <<~S
        * ASSERTION FAILED - assert_element
          Element with selector #{selector} was found, but never evalated to true for lambda located at:
          #{callback.source_location.join ":"}
        S
      end
    end

    true
  end

  def assert_element_contains_inner_text selector, text, timeout: default_timeout
    puts "* ASSERT - assert_element_inner_text #{selector}, #{text}, timeout: #{timeout}"

    failure = lambda { |e|
      if !e
        raise <<~S
              * ASSERTION FAILED - element with #{selector} was not found.
              S
      else
        raise <<~S
              * ASSERTION FAILED - element inner text did not contain expected text.
                expected: #{text}
                actual:   #{e.inner_text}
              S
      end
    }

    assert_element selector,
                   timeout: timeout,
                   callback: lambda { |e| e.inner_text.include? text },
                   failure: failure

    true
  end

  def assert_element_inner_text selector, text, timeout: default_timeout
    puts "* ASSERT - assert_element_inner_text #{selector}, #{text}, timeout: #{timeout}"

    failure = lambda { |e|
      if !e
        raise <<~S
              * ASSERTION FAILED - element with #{selector} was not found.
              S
      else
        raise <<~S
              * ASSERTION FAILED - element inner text didn't match expected text.
                expected: #{text}
                actual:   #{e.inner_text}
              S
      end
    }

    assert_element selector,
                   timeout: timeout,
                   callback: lambda { |e| e.inner_text == text },
                   failure: failure

    true
  end

  def assert_element_value selector, expected, timeout: default_timeout
    puts "* ASSERT - assert_element_value #{selector}, #{expected}, timeout: #{timeout}"

    failure = lambda { |e|
      if !e
        raise <<~S
              * ASSERTION FAILED - element with #{selector} was not found.
              S
      else
        raise <<~S
              * ASSERTION FAILED - element value didn't match expected value.
                expected: #{expected}
                actual:   #{e.value}
              S
      end
    }

    assert_element selector,
                   timeout: timeout,
                   callback: lambda { |e| e.value == expected.to_s },
                   failure: failure

    true
  end

  def assert_element_exists selector, timeout: default_timeout
    puts "* ASSERT - assert_element_exists #{selector}, timeout: #{timeout}"
    element selector, timeout: default_timeout
    true
  rescue
    raise <<~S
    * ASSERTION FAILED - element with #{selector} does not exist on the page.
    S
  end

  def assert_js js, timeout: default_timeout
    puts "* ASSERT - assert_js"

    assertion_current_timeout = 0
    assertion_passed = false

    while !assertion_passed && assertion_current_timeout <= timeout
      assertion_passed = evaluate_js js
      assertion_current_timeout += 0.1
      sleep 0.1
    end

    if !assertion_passed
      raise <<~S
            * ASSERTION FAILED - js assertion never returned true.
            #{js}
            S
    end
  end
end
