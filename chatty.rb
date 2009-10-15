#!/usr/bin/env ruby

#chatty
require 'rubygems'
require 'curb'
require 'nokogiri'

require 'highline/import'
require 'levenshtein'
require 'string_scorer/string_scorer.rb'

pass = `cat ~/.gmail_pass`

c = Curl::Easy.http_post("https://www.google.com/accounts/ClientLogin",
                           Curl::PostField.content('accountType', 'GOOGLE'),
                           Curl::PostField.content('Email', 'cory.forsyth@gmail.com'),
                           Curl::PostField.content('Passwd', pass),
                           Curl::PostField.content('service', 'cp'),
                           Curl::PostField.content('source', 'bantico-chatty-1'))

if c.response_code != 200
  puts "Error authorizing"
else
  auth = c.body_str.match(/Auth=(.*)/)[1]
  puts "'#{auth}'"
end

puts "Loading contacts..."
url = "http://www.google.com/m8/feeds/contacts/cory.forsyth@gmail.com/full?max-results=200"
c = Curl::Easy.perform(url) do |curl|
  curl.headers["Authorization"] = "GoogleLogin auth=#{auth}"
end

DOC = Nokogiri::XML.parse(c.body_str)

contacts = {}

DOC.search("entry").each do |entry|
  next unless entry.at("title") && title = entry.at("title").content
  next if title =~ /^\s*$/
  
  emails = {}
  entry.xpath("./gd:email").collect do |email_node|
    label = email_node['label'] || email_node['rel'].match(/#(.*)/)[1]
    emails[email_node['address']] = label
  end
  
  next if emails.empty?
  
  contacts[title] = emails
end

puts contacts.inspect

name = HighLine.ask("name? ")

puts contacts.keys.inspect
contacts.keys.each do |con|
  puts con
  puts con.downcase.score(name, :quicksilver)
end

found = contacts.keys.sort {|a,b| b.downcase.score(name.downcase, :quicksilver) <=> a.downcase.score(name.downcase, :quicksilver)}

puts found.inspect