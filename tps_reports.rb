#!/usr/bin/env ruby

require 'ping'
require 'net/http'
require 'uri'

DEBUG=false

def connected?
  Ping.pingecho("209.20.90.171", 10, 80)
end

def send_text(msg=nil)
  phone_number = ARGV[1] || "9176645212"
  email = "#{phone_number}@txt.att.net"
  msg ||= "online!"
  url = "http://209.20.90.171/ruby.rhtml?email=#{email}&msg=#{msg}&subject=#{msg}"
  # Net::HTTP.get URI.parse(url)
  
  url2 = "http://209.20.90.171/ruby.rhtml?email=cory.forsyth@gmail.com&msg=#{msg}&subject=#{msg}"
  Net::HTTP.get URI.parse(url2)
end

if ARGV[0] != 'TEST'
  pid = fork do
    startup = true
    connected = false
    sleep_time = 10
    loop do
      puts "looping..." if DEBUG
      if !connected
        puts "not connected to start"  if DEBUG
        # check for connectivity
        if connected?
          puts "connected from false -> true. sending text." if DEBUG
          connected = true
          msg = if startup
            "Startingup" 
          else
            "online!"
          end
          send_text(msg)
        end
      else
        if !connected?
          puts "connected from true -> false" if DEBUG
          connected = false
        end
      end
      
      puts "sleeping #{sleep_time}" if DEBUG
      startup = false
      sleep sleep_time
    end
  end
  
  Process.detach(pid)
else
  $stdout.sync = true

  print "Testing net connectivity..."
  if connected?
    puts "connected."

    print "Sending test text..."
      send_text("test")
    puts "sent."
  else
    puts "not connected."
  end
end