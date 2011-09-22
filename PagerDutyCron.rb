#!/usr/bin/ruby

# Copyright (C) 2011 - Gareth Llewellyn
# 
# This file is part of https://github.com/NetworksAreMadeOfString/PagerDuty-Schedule-to-Asterisk
#
# A ruby script to query the PagerDuty schedule and update an asterisk DB variable to allow
# redirection of calls to the current on-call person e.g.
#
#    [ops-oncall]
#    exten => 123456,1,Queue(ops,tT,,,16)
#    exten => 123456,2,Dial(IAX2/XXXX@XXXXX/${DB(oncall/phone)})
#    
# 
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
# 
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>


require 'open-uri'
require 'uri'
require 'rubygems'
require 'net/http'
require 'net/https'
require 'json'

#PagerDuty API Key
pagerduty_username    = ''
pagerduty_password    = ''
pagerduty_schedule    = ''
pagerduty_subdomain   = ''

#Asterisk Stuff
asterisk_db           = 'oncall'
asterisk_key          = 'phone'
asterisk_path         = '/usr/sbin/asterisk'

#ContactDetails HashMap
ContactDetails        = Hash["User 1", 441234567890,
                             "User 2", 441234567890,
                             "User 3", 441234567890]
#Time details
time      = Time.new
Day       = time.day
Month     = time.month
Year      = time.year

http = Net::HTTP.new("#{pagerduty_subdomain}.pagerduty.com", 443)
http.use_ssl = true
path = "/api/v1/schedules/#{pagerduty_schedule}/entries?since=#{Year}-#{Month}-#{Day}&until=#{Year}-#{Month}-#{Day}"
req = Net::HTTP::Get.new(path)
req.basic_auth pagerduty_username, pagerduty_password
resp, data = http.request(req)

#Check if the response code was a good 200
if resp.code.to_i == 200
  puts "Received a 200 response"
  PagerDutyJSON = JSON.parse(data)
  
  #Do we have any entries in the returned JSON
  if PagerDutyJSON.has_key? 'entries'
    OnCallUser = PagerDutyJSON['entries'][0]['user']['name']
    OnCallNumber = ContactDetails[OnCallUser].to_s()
    puts "On call person is #{OnCallUser} which makes their contact details: #{OnCallNumber}"
    system("#{asterisk_path} -rx \"database put #{asterisk_db} #{asterisk_key} #{OnCallNumber}\"")
  else
    #Don't change the file
    puts "An error decoding the JSON occured"
  end
else
  #Don't change the file
  puts "An error occured"
end
