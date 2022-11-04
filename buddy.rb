require 'fileutils'

ferrum_exists = `gem list -i "^ferrum$"`.strip == "true"

if !ferrum_exists
  puts <<~S
  * INFO - ferrum not found
    Please run: gem install ferrum
  S
  exit -1
end

original_verbose, $VERBOSE = $VERBOSE, nil
REQUIRES = [
  './lib/lib.rb',
  './lib/assertions.rb'
]
REQUIRES.each { |f| require f }
$VERBOSE = original_verbose

FileUtils.mkdir_p('./logs')

def reload_buddy
  REQUIRES.each { |f| load f }
end

def start_watcher_thread
  @reload_thread = Thread.new do
    @reload_mtimes ||= {}
    REQUIRES.each do |f|
      @reload_mtimes[f] = File.mtime f
    end
    loop do
      changed_k, changed_v = REQUIRES.find do |f|
        @reload_mtimes[f] != File.mtime(f)
      end
      if changed_k
        puts "* INFO: Reloaded #{changed_k}."
        begin
          reload_buddy
        rescue Exception => e
          puts "* ERROR: Reloading failed\n#{e}"
        end
      end
      REQUIRES.each do |f|
        @reload_mtimes[f] = File.mtime(f)
      end
      sleep 1
    end
  end
end

def initialize_repl
  reload_buddy
  start_watcher_thread
end

at_exit do
  if !$!
    puts "* SUCCESS - #{$0} #{ARGV.join " "}"
  end
end

system "mkdir -p logs"

if !@first_started_logged
  open "logs/#{Process.pid}-browser-console.log", 'a' do |f|
    f.puts "* BUDDY STARTED - #{Time.now}"
    f.puts "  #{$0} #{ARGV.join " "}"
  end

  open "logs/pid.log", 'a' do |f|
    f.puts <<~S
           * PID
             process: #{$0} #{ARGV.join " "}
             pid: #{Process.pid}
             time: #{Time.now}
             browser console log path: logs/#{Process.pid}-browser-console.log
           S
  end

  @first_started_logged = true
end
