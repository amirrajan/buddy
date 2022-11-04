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
