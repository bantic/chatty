#!/usr/bin/env ruby

require 'ping'
require 'net/http'
require 'uri'

DEBUG=false

def connected?
  Ping.pingecho("209.20.90.171", 10, 80)
end

def send_text
  phone_number = ARGV[1] || "4352322390"
  email = "#{phone_number}@txt.att.net"
  url = "http://209.20.90.171/ruby.rhtml?email=#{email}&msg=online!&subject=online!"
  Net::HTTP.get URI.parse(url)
end

if ARGV[0] == 'GO'
  pid = fork do
    connected = false
    sleep_time = 30
    loop do
      puts "looping..." if DEBUG
      if !connected
        puts "not connected to start"  if DEBUG
        # check for connectivity
        if connected?
          puts "connected from false -> true. sending text." if DEBUG
          connected = true
          send_text
        end
      else
        if !connected?
          puts "connected from true -> false" if DEBUG
          connected = false
        end
      end
      
      puts "sleeping #{sleep_time}" if DEBUG
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
      send_text
    puts "sent."
  else
    puts "not connected."
  end
end