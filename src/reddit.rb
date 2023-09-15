usernames_to_keys = [
  # ["XXXXXXXXXXXXXXXXX",  "USERNAME"],
]

def send_steam_key username, key
  base_url = "https://www.reddit.com/message/compose?to="
  goto "#{base_url}#{username}"
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  press_tab
  type  "Steam Key for A Dark Room"
  press_tab
  type  "Here's your key: #{key}"
  press_enter
  press_enter
  type "I hope you enjoy the game and decide to pay it forward/gift the game to a friend."
  press_tab
  press_enter
  sleep 5
  screenshot "#{username}.png"
end

goto "http://reddit.com"
puts "LOGIN TO REDDIT THEN PRESS ENTER"
gets

usernames_to_keys.each do |(steam_key, username)|
  File.open("processed.txt", "a") do |file|
    file.puts "#{steam_key} #{username}"
  end
  send_steam_key username, steam_key
  sleep 30
end

def get_after url, after = nil
  goto "#{url}?after=#{after}"
  pre = element "pre"
  pre_json = JSON.parse pre.inner_text
  pre_json["data"]["after"]
end

def get_comments url, after = nil
  goto "#{url}?after=#{after}"
  pre = element "pre"
  pre_json = JSON.parse pre.inner_text
  pre_json["data"]["children"].map { |h| { text: h["data"]["body"], link: h["data"]["link_permalink"] } }
rescue Exception => e
  puts "#{e}"
  puts element("body").inner_text
end

def search_comments url: "https://www.reddit.com/user/amirrajan/comments.json", after: "", search:, **rest;
  c = get_comments url, after
  s = c.find_all { |c| c[:text].downcase.include? search.downcase }
  { comments: s, url: url, after: get_after(url, after), search: search }
end

def search_many search
  goto "http://reddit.com"
  puts "LOGIN TO REDDIT THEN PRESS ENTER"
  gets
  $r = { search: search }
  loop do
    $r = search_comments **$r
    pp $r
    puts "Press enter to continue searching..."
    gets
  end
end
