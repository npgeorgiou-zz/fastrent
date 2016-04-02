environment = ARGV[0]
if environment != 'development' && environment != 'production'
  raise "Specify either 'development' or 'production' as script argument"
  end

require 'unirest'
require_relative 'ar.rb'
require_relative 'models/system_var'
require_relative 'models/user'

# Get email increment
system_var = System_var.first
if !system_var
  system_var = System_var.new({email_increment: 1})
  system_var.save
end

# 0 30 60 120 240 1440

puts system_var.email_increment

if system_var.email_increment % 1 === 0
  puts 'getting 30 mins users'
  users = get_users_with_email_frequency(30)
end

if system_var.email_increment % 2 === 0
  puts 'getting 60 mins users'
  users = get_users_with_email_frequency(30, 60)
end

if system_var.email_increment % 4 === 0
  puts 'getting 120 mins users'
  users = get_users_with_email_frequency(30, 60, 120)
end

if system_var.email_increment % 8 === 0
  puts 'getting 240 mins users'
  users = get_users_with_email_frequency(30, 60, 120, 240)
end

if system_var.email_increment % 48 === 0
  puts 'getting 1440 mins users'
  users = get_users_with_email_frequency(30, 60, 120, 240, 1440)
end

# TODO: I think Mandrill API allows for an array of emails to be provided
users.each do |user|
  p user.email
  # Send email
end

# Increment email system var
system_var.update(email_increment: system_var.email_increment + 1)

BEGIN {
  def get_users_with_email_frequency (*args)
    args.map! {|e| e.to_s}
    users = User.where("settings->>'emailFrequency' IN (?)", args)
    return users
  end
}
