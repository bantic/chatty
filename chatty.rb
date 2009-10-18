#!/usr/bin/env ruby

#chatty
require 'rubygems'
require 'curb'
require 'nokogiri'

require 'highline/import'
# require 'levenshtein'
require 'string_scorer/string_scorer.rb'
require 'send_gmail'

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
url = "http://www.google.com/m8/feeds/contacts/cory.forsyth@gmail.com/full?max-results=10000"
c = Curl::Easy.perform(url) do |curl|
  curl.headers["Authorization"] = "GoogleLogin auth=#{auth}"
end

DOC = Nokogiri::XML.parse(c.body_str)

contacts = {}

DOC.search("entry").each do |entry|
  next unless entry.at("title") && title = entry.at("title").content
  title ||= ""
  
  emails = {}
  entry.xpath("./gd:email").collect do |email_node|
    label = email_node['label'] || email_node['rel'].match(/#(.*)/)[1]
    emails[email_node['address']] = label
  end
  
  next if emails.empty?
  
  contacts[title] = emails
end

puts contacts.inspect

number = -1
until number != -1 do
  name = HighLine.ask("name? ")

  found = contacts.collect {|c| score = c[0].downcase.score(name.downcase, :quicksilver); next if score < 0.2; [c, score] }.compact.sort{|a,b| b[1] <=> a[1]}.slice(0,5)
  found = found.collect{|c,score| c}
  puts found.inspect

  found.each_with_index do |contact,index|
    puts "#{index}: #{contact[0]}"
  end
  number = HighLine.ask("number? ").to_i
end

contact = found[number]
email = if contact[1].size > 1
  contact[1].each_with_index do |array, index|
    puts "#{index}: <#{array[0]}> (#{array[1]})"
  end
  number = HighLine.ask("number? ").to_i
  contact[1].to_a[number][0]
else
  contact[1].to_a.flatten[0]
end
puts "email: #{email}"

msg = HighLine.ask("message? ")

email = found[number][1].keys.first
SendGMail.send_gmail({:to => email, :subject => msg, :body => ""})
puts "sent."