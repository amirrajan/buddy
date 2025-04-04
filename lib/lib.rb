require 'ferrum'

module Buddy
  def start_browser
    stop_browser
    @browser = nil
    @browser_window_size = [1280, 720]
    @browser = Ferrum::Browser.new headless: false,
                                   browser_path: binary_path,
                                   window_size: @browser_window_size
    @browser.position = { top: 0, left: 0 }
    @browser.page.command("Console.enable")
    @browser.on('Console.messageAdded') do |data|
      if data["message"]["level"] == "log"
        open "logs/#{Process.pid}-browser-console.log", 'a' do |f|
          f.puts "[#{data["message"]["level"]}] #{data["message"]["text"]}"
        end
      end
    end
  end

  def browser_url
    @browser.url
  end

  def restart_browser
    url = browser_url
    stop_browser
    start_browser
    goto url
  end

  def stop_browser
    @browser.page.close
    @browser.quit
  rescue
  ensure
    @browser = nil
  end

  def goto url
    start_browser if !@browser
    @browser.go_to url
  end

  def sandbox
    load "./src/sandbox.rb"
  end

  def retry_until_true timeout: default_timeout, &block
    result = nil
    current_time = 0

    while !result && (current_time <= timeout)
      result = block.call
      sleep 0.1
      current_time += 0.1
    end

    result
  end

  def iframes_accessible?
    has_blank_iframes = @browser.frames.any? { |f| f.page.url == "about:blank" }
    return !has_blank_iframes
  end

  def element_css selector, timeout: default_timeout
    el = nil

    retry_until_true timeout: timeout do
      el ||= @browser.at_css selector
      if !el
        if iframes_accessible?
          @browser.frames.each do |f|
            el ||= f.page.at_css selector
          end
        end
      end
      el
    end
    el
  rescue Exception => e
    return nil
  end

  def element_xpath xpath, timeout: default_timeout
    el = nil
    retry_until_true timeout: timeout do
      el ||= @browser.at_xpath xpath
      if !el
        if iframes_accessible?
          @browser.frames.each do |f|
            el ||= f.at_xpath xpath
          end
        end
      end
      el
    end
    el
  rescue Exception => e
    return nil
  end

  def element selector, timeout: default_timeout
    result   = element_css selector, timeout: timeout
    result ||= element_xpath selector, timeout: timeout
    raise "* ERROR - Unable to find #{selector}." if !result
    $e = result
    $sel = selector
    result
  end

  def element_or_nil selector, timeout: default_timeout
    result   = element_css selector, timeout: timeout
    result ||= element_xpath selector, timeout: timeout
    $e = result
    $sel = selector
    result
  end

  def click_js selector, index: nil
    if index
      @browser.page.evaluate("document.querySelectorAll(#{selector.inspect})[#{index}].click()")
    else
      @browser.page.evaluate("document.querySelector(#{selector.inspect}).click()")
    end
  end

  def click selector, timeout: default_timeout, index: nil
    if selector.is_a? Ferrum::Node
      click_element selector
    elsif index
      es = elements selector, timeout: timeout
      e = es[index]
      if !e
        raise "* ERROR - Element at index #{index} for selector #{selector} was nil/does not exist."
      end
      click_element e
    else
      e = element selector, timeout: timeout
      recommend_better_selector_js selector, e
      click_element e
    end
    true
  end

  def elements_css selector, timeout: default_timeout
    element_or_nil selector, timeout: timeout
    @browser.page.css selector
  rescue
    return nil
  end

  def elements_xpath selector, timeout: default_timeout
    element_or_nil selector, timeout: timeout
    @browser.page.xpath selector
  rescue
    return nil
  end

  def elements selector, timeout: default_timeout
    $es = elements_css(selector, timeout: timeout) || elements_xpath(selector, timeout: timeout)
    $sel = selector
    $es
  end

  def click_element element
    raise "* ERROR - click_element #{element} was not a Ferrum::Node." if !element.is_a? Ferrum::Node
    execute_js File.read "./lib/lib.js"
    element.evaluate "window.buddy.scrollIntoViewIfNeeded(this)"
    element.click
    nil
  end

  def type keys
    @browser.keyboard.type keys
    nil
  end

  def press_enter
    type [:enter]
  end

  def press_tab
    type [:tab]
  end

  def tag_with_text tag, text, timeout: default_timeout
    selector = %Q[//#{tag}[contains(text(), "#{text}")]]
    element selector
  end

  def click_tag_with_text tag, text, timeout: default_timeout
    e = tag_with_text tag, text, timeout: timeout
    click_element e
  end

  def click_a_with_text text, timeout: default_timeout
    click_tag_with_text "a", text, timeout: timeout
  end

  def click_span_with_text text, timeout: default_timeout
    click_tag_with_text "span", text, timeout: timeout
  end

  def click_button_with_text text, timeout: default_timeout
    click_tag_with_text "button", text, timeout: timeout
  end

  def click_div_with_text text, timeout: default_timeout
    click_tag_with_text "div", text, timeout: timeout
  end

  def scrubbed_caller
    caller.reject do |c|
      c.include?("/lib.rb")          ||
        c.include?("/ruby-lex.rb")     ||
        c.include?("/workspace.rb")    ||
        c.include?("/irb:")            ||
        c.include?("lib/ruby")         ||
        c.include?("(irb):")           ||
        c.include?("/irb.rb")
    end
  end

  def recommend_better_selector_js selector_used, e
    execute_js File.read "./lib/lib.js"

    begin
    better_selector = e.evaluate("window.buddy.recommendBetterSelector(#{selector_used.inspect}, this)")
    rescue
    end

    if better_selector
      puts <<-S
* INFO - Consider using #{better_selector} instead of the selector #{selector_used}.
** CALLER
#{scrubbed_caller.join "\n" }
S
    end
  end

  def click_input_with_value value, timeout: default_timeout
    click %(//input[contains(@value, '#{value}')]), timeout: timeout
  end

  def find_label_with_text text, timeout: default_timeout
    label_selector  = %(//label[contains(text(), '#{text}')])
    element label_selector, timeout: timeout
  end

  def find_input_with_value text, timeout: default_timeout
    input_selector  = %(//input[contains(@value, '#{text}')])
    element input_selector, timeout: timeout
  end

  def find_tag_with_text tag, text, timeout: default_timeout
    selector = %(//#{tag}[contains(text(), '#{text}')])
    element selector, timeout: timeout
  end

  def find_tag_with_value tag, text, timeout: default_timeout
    selector = %(//#{tag}[contains(@value, '#{text}')])
    element selector, timeout: timeout
  end

  def info elements
    if !elements.is_a? Enumerable
      info_element elements
    else
      elements.each_with_index { |element, index| info_element element, index: index }
    end
  end

  def info_element element, index: nil
    puts "* HELP"
    puts "  index:    #{index}" if index
    puts "  selector: #{recommend_selector_js element}"
    puts "  tag name: #{element.tag_name}"
    puts "  text: #{element.text}" if element.text && element.text.strip.length > 0 && element.text.strip.length < 50
  end

  def search text, timeout: default_timeout
    search_results text, timeout: timeout
    true
  end

  def search_results text, timeout: default_timeout
    puts "* ACTION - search #{text}, timeout: #{timeout}"
    text_selector = %(//text()[contains(., #{text.inspect})])
    value_selector = %(//*[contains(@value, #{text.inspect})])
    puts "  text_selector: #{text_selector}"
    puts "  value_selector: #{value_selector}"

    found_selector_text = elements text_selector, timeout: timeout
    found_selector_value = elements value_selector, timeout: timeout
    found_selector_literal = []
    begin
      found_selector_literal = elements text, timeout: timeout
    rescue
    end

    found_elements = [found_selector_text, found_selector_value, found_selector_literal].flatten.compact

    if found_elements.length == 0
      $s  = nil
    else
      puts "found_elements length #{found_elements.length}"
      info found_elements
      $s  = found_elements
      $s
    end
  end

  def recommend_selector_js element
    execute_js File.read "./lib/lib.js"
    element.evaluate "window.buddy.recommendSelector(this)"
  end

  def find_text_or_nil text, timeout: default_timeout
    puts "* ACTION - find_text_or_nil #{text}, timeout: #{timeout}"
    span_selector         = %(//span[contains(text(), "#{text}")])
    div_selector          = %(//div[contains(text(), "#{text}")])
    button_selector       = %(//button[contains(text(), "#{text}")])
    a_selector            = %(//a[contains(text(), "#{text}")])
    input_selector        = %(//input[contains(@value, '#{text}')])
    label_selector        = %(//label[contains(text(), '#{text}')])
    td_selector           = %(//td[contains(text(), '#{text}')])
    tr_selector           = %(//tr[contains(text(), '#{text}')])
    option_text_selector  = %(//option[contains(text(), '#{text}')])
    option_value_selector = %(//option[contains(@value, '#{text}')])

    found_selector = if element_or_nil span_selector, timeout: timeout
                       puts "* NOTE: ~span~ found with text, use ~(click|find)_span_with_text~ to speed up the automation."
                       span_selector
                     elsif element_or_nil div_selector, timeout: timeout
                       puts "* NOTE: ~div~ found with text, use ~(click|find)_div_with_text~ to speed up the automation."
                       div_selector
                     elsif element_or_nil button_selector, timeout: timeout
                       puts "* NOTE: ~button~ found with text, use ~(click|find)_button_with_text~ to speed up the automation."
                       button_selector
                     elsif element_or_nil a_selector, timeout: timeout
                       puts "* NOTE: ~a~ found with text, use ~(click|find)_a_with_text~ to speed up the automation."
                       a_selector
                     elsif element_or_nil input_selector, timeout: timeout
                       puts "* NOTE: ~input~ found with text, use ~(click|find)_input_with_value~ to speed up the automation."
                       input_selector
                     elsif element_or_nil label_selector, timeout: timeout
                       puts "* NOTE: ~label~ found with text, use ~(click|find)_label_with_text~ to speed up the automation."
                       label_selector
                     elsif element_or_nil td_selector, timeout: timeout
                       puts "* NOTE: ~td~ found with text, use ~(click|find)_tag_with_text \"td\", #{text.inspect}~ to speed up the automation."
                       td_selector
                     elsif element_or_nil tr_selector, timeout: timeout
                       puts "* NOTE: ~tr~ found with text, use ~(click|find)_tag_with_text \"tr\", #{text.inspect}~ to speed up the automation."
                       td_selector
                     elsif element_or_nil option_text_selector, timeout: timeout
                       puts "* NOTE: ~option~ found with text, use ~(click|find)_tag_with_text \"option\", #{text.inspect}~ to speed up the automation."
                       option_text_selector
                     elsif element_or_nil option_value_selector, timeout: timeout
                       puts "* NOTE: ~option~ found with value, use ~(click|find)_tag_with_value \"option\", #{text.inspect}~ to speed up the automation."
                       option_value_selector
                     end

    if !found_selector
      nil
    else
      e = element found_selector
      recommend_better_selector_js found_selector, e
      e
    end
  end

  def find_text text, timeout: default_timeout
    puts "* ACTION - find_text #{text}"
    e = find_text_or_nil text, timeout: 0

    e = find_text_or_nil text, timeout: timeout if !e

    if !e
      raise "* ERROR - no element found containing text =#{text}=."
    end

    e
  end

  def click_text text, timeout: default_timeout
    puts "* ACTION - click_text #{text}"
    e = find_text text, timeout: timeout
    click_element e
  end

  def execute_js source
    @browser.execute source
  end

  def evaluate_js source
    @browser.evaluate source
  end

  def browser
    @browser
  end

  def default_timeout
    @default_timeout ||= 1
  end

  def set_default_timeout value
    @default_timeout = value
  end

  def with_timeout value
    current_default_timeout = default_timeout
    set_default_timeout value
    yield if block_given?
    set_default_timeout current_default_timeout
  end

  def run file
    puts "* ACTION - run #{file}"
    File.write ".last-file-ran", file
    load file
  end

  def rerun
    puts "* ACTION - rerun"
    if !File.exist? ".last-file-ran"
      last_file = "./src/sandbox.rb"
    else
      last_file = File.read ".last-file-ran"
    end

    last_file.strip!

    if last_file.length == 0
      last_file = "./src/sandbox.rb"
    elsif !File.exist? last_file
      puts "* WARNING: I can't find a file with the name =#{last_file}=. So I'm gonna run =./src/sandbox.rb= for you instead."
    end

    run last_file
  end

  def set_value selector, value
    e = element selector
    e.evaluate %Q(this.setAttribute('value', #{value.inspect}))
    e.evaluate %Q(this.value = #{value.inspect})
  end

  def reload_browser
    puts "* ACTION - reload_browser"
    browser.refresh
    $e = nil
    $sel = nil
    true
  end

  def drag_and_drop from:, to:, index: 0;
    puts "* ACTION - mouse_drag_and_drop_emulate from: #{from} to: #{to}"

    assert_element_exists from
    assert_element_exists to

    execute_js <<~S
    let findUpwards = function(element, selector) {
      let r = element.querySelector(selector);
      if (r) return r;
      if (element.parentElement) return findUpwards(element.parentElement, selector);
      return null;
    };
    let mouseEventCreate = function(name, element, dataTransfer) {

      let mouseEvent = new MouseEvent(name);
      if (dataTransfer) {
        mouseEvent.dataTransfer = dataTransfer;
      }
      mouseEvent.index = #{index};
      mouseEvent.target = element;
      return mouseEvent;
    };

    a = document.querySelector(#{from.inspect});
    if (!a.attributes['draggable']) {
      a = findUpwards(a, "[draggable]");
    }

    b = document.querySelector(#{to.inspect});
    if (!b.getAttribute("ondrop")) {
      b = findUpwards(b, "[ondrop]");
    }
    if (!b) {
      throw "droppable to selector not found";
    }
    let dataTransfer = new DataTransfer();
    a.scrollIntoView();
    b.scrollIntoView();
    a.dispatchEvent(mouseEventCreate('dragstart', a, dataTransfer));
    a.dispatchEvent(mouseEventCreate('drag', a, dataTransfer));
    b.dispatchEvent(mouseEventCreate('dragenter', b, dataTransfer));
    b.dispatchEvent(mouseEventCreate('dragover', b, dataTransfer));
    b.dispatchEvent(mouseEventCreate('drop', b, dataTransfer));
  S
  end

  def open_chrome_devtools_protocol
    system "open https://chromedevtools.github.io/devtools-protocol/"
  end

  def parent_element selector, timeout: default_timeout
    e = element selector, timeout: timeout
    evaluate_js "document.querySelector(#{selector.inspect}).parentElement"
  end

  def highlight selector
    e = element selector
    @browser.page.command("Overlay.enable")
    @browser.page.command("DOM.highlightNode", nodeId: $e.node_id, highlightConfig: { showInfo: true, borderColor: { r: 255, g: 0, b: 0 } })
  end

  def screenshot path
    @browser.screenshot path: path
  end

  def is_windows?
    RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
  end

  def binary_path
    if is_windows?
      "./bin/chrome-win/chrome.exe"
    else
      "./bin/Chromium.app/Contents/MacOS/Chromium"
    end
  end
end

self.singleton_class.include Buddy

# todo
# browser.page.command("Overlay.enable")
# browser.page.command("DOM.highlightNode", nodeId: $e.node_id, highlightConfig: { borderColor: { r: 255, g: 0, b: 0 } })
