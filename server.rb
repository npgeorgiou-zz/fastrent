require 'webrick'
require 'yaml'
require 'json'
environment = ARGV[0]
if environment != 'development' && environment != 'production'
  raise "Specify either 'development' or 'production' as script argument"
end

require 'digest'
require_relative 'ar.rb'
require_relative 'handlers/email.rb'
require_relative 'util/hash'

config = YAML.load_file('config/config.yaml')

port = ENV['PORT'] || config.dig("server.#{environment}.port")
puts "Starting up server at port #{port}..."
server = WEBrick::HTTPServer.new(:Port => port, :DocumentRoot => File.dirname(__FILE__) + '/public')

server.mount_proc '/fetch' do |req, res|
  active = false

  token   = req.header['authorization'][0]
  body    = JSON.parse(req.body, object_class: OpenStruct)
  site    = body.site
  region  = body.region
  type    = body.type
  minRent = body.minRent
  maxRent = body.maxRent
  from    = body.from

  puts body
  # Check if a user with this token exists
  if token != 'null'
    user = User.includes(:memberships).find_by token: token
    if user.nil?
      res.status = 404
      res.body   = 'No user with these credentials found'
      next
    end
  end

  # Check if user has an active membership
  user && user.memberships.each do |membership|
    if !membership.expired?
      active = true
      break
    end
  end

  # Get ads
  if from != 0
    boligportalAds = Ad.where(
        'site IN (?) AND region IN (?) AND ad_type IN (?) AND rent >= ? AND rent <= ? AND posted < ?',
        site,
        region,
        type,
        [minRent],
        [maxRent],
        from
    ).limit(6).order(posted: :desc)
  else
    boligportalAds = Ad.where(
        'site IN (?) AND region IN (?) AND ad_type IN (?) AND rent >= ? AND rent <= ?',
        site,
        region,
        type,
        [minRent],
        [maxRent]
    ).limit(6).order(posted: :desc)
  end

  # Change ads url if client is not authorized
  if !active
    boligportalAds.each do |ad| ad.url = 'hidden' end
  end

  res.body = boligportalAds.to_json
end
server.mount_proc '/fetch-new' do |req, res|
  active = false

  token   = req.header['authorization'][0]
  body    = JSON.parse(req.body, object_class: OpenStruct)
  site    = body.site
  region  = body.region
  type    = body.type
  minRent = body.minRent
  maxRent = body.maxRent
  from    = body.from

  puts body
  # Check if a user with this token exists
  if token != 'null'
    user = User.includes(:memberships).find_by token: token
    if user.nil?
      res.status = 404
      res.body   = 'No user with these credentials found'
      next
    end
  end

  # Check if user has an active membership
  user && user.memberships.each do |membership|
    if !membership.expired?
      active = true
      break
    end
  end

  # Get ads
  if from != 0
    boligportalAds = Ad.where(
        'site IN (?) AND region IN (?) AND ad_type IN (?) AND rent >= ? AND rent <= ? AND posted > ?',
        site,
        region,
        type,
        [minRent],
        [maxRent],
        from
    ).limit(6).order(posted: :desc)
  else
    boligportalAds = Ad.where(
        'site IN (?) AND region IN (?) AND ad_type IN (?) AND rent >= ? AND rent <= ?',
        site,
        region,
        type,
        [minRent],
        [maxRent]
    ).limit(6).order(posted: :desc)
  end

  # Change ads url if client is not authorized
  if !active
    boligportalAds.each do |ad| ad.url = 'hidden' end
  end

  res.body = boligportalAds.to_json
end

server.mount_proc '/user/register' do |req, res|
  body = JSON.parse(req.body, object_class: OpenStruct)
  p body
  email    = body.email
  password = body.password

  # Check if email is already in database
  if User.exists?(email: email)
    res.status = 409
    res.body   = 'User with that email already exists'
    next
  end

  # Generate salt
  salt = SecureRandom.hex(32)

  # Append salt to password and hash them
  hashed_pass = Digest::SHA2.hexdigest(salt + password)

  # TODO: DO these 2 operations in a transaction
  # Create user
  user = User.new(
    {
      email:       email,
      password:    hashed_pass,
      salt:        salt,
      token:       SecureRandom.hex(32),
      settings:    nil,
      created:     Time.now.to_i
    }
  )
  user.save

  # Create membership
  membership = Membership.new(
    {
      user_id:   user.id,
      requested: Time.now.to_i,
      paid:      Time.now.to_i,
      created:   Time.now.to_i,
      price:     50
    }
  )

  membership.save

  # Send email to new user
  Email.new().send(user.email, 'Welcome to FastRent', 'We have registered your membership')

  # TODO: Send sms to me informing abt new registration

  res.body = 'OK'
end
server.mount_proc '/user/login' do |req, res|
  body = JSON.parse(req.body, object_class: OpenStruct)
  puts body
  email    = body.email
  password = body.password

  # Check if a user with this email exists
  if !User.exists?(email: email)
    res.status = 409
    res.body   = 'No user with these credentials found'
    next
  end

  # Get user
  user = User.where(email: email).take

  # Append salt to password and hash them
  salt        = user.salt
  hashed_pass = Digest::SHA2.hexdigest(salt + password)

  # Compare
  if (hashed_pass != user.password)
    res.status = 409
    res.body   = 'No user with these credentials found'
    next
  end

  # Strip private info
  result = {
      token:    user.token,
      settings: user.settings
  }.to_json

  res.body = result
end
server.mount_proc '/user/logout' do |req, res|
  token   = req.header['authorization'][0]
  puts token

  # Check if a user with this token exists
  if token != 'null'
    user = User.includes(:memberships).find_by token: token
    if user.nil?
      res.status = 404
      res.body   = 'No user with these credentials found'
      next
    end
  end
  res.body = 'OK'
end
server.mount_proc '/user/update/settings' do |req, res|
  token = req.header['authorization']
  new_settings = req.body
  puts new_settings

  # Check if a user with this token exists
  user = User.includes(:memberships).find_by token: token
  if user.nil?
    res.status = 404
    res.body   = 'user not found'
    next
  end

  # Check if user has an active membership
  active = false
  user.memberships.each do |membership|
    if !membership.expired?
      active = true
      break
    end
  end

  if !active
    res.status = 403
    res.body   = 'membership expired'
    next
  end

  # Update settings
  user.update(settings: new_settings)
  res.body = user.settings.to_json

end
server.mount_proc '/user/password-request' do |req, res|
  body = JSON.parse(req.body, object_class: OpenStruct)
  p body
  email = body.email

  # Get user with this email
  user = User.where(email: email).take
  puts user

  if !user.nil?
    # Create a password reset token
    actiontoken = Actiontoken.new(
        {
            key:     SecureRandom.hex(32), #TODO: Ensure uniqueness of token,
            data:    {
                'model'    => 'User',
                'model_id' => user.id,
                'action'   => 'new_password',
            },
            created: Time.now.to_i
        }
    )
    actiontoken.save

    # Send email to user
    Email.new().send(
        user.email,
        'Your new password reset link',
        "Click here in the next 15 mins to set your new password \n http://localhost:3000/views/main.html#/set-new-password?t=#{actiontoken.key}"
    )

  end

  # Always return OK
  res.body = 'OK'
end
server.mount_proc '/user/password-reset' do |req, res|
  body = JSON.parse(req.body, object_class: OpenStruct)
  puts body
  new_password = body.new_password
  token_key    = body.token_key

  if (new_password.nil? || token_key.nil?)
    res.status = 400
    res.body   = 'missing input'
    next
  end

  # Get actiontoken
  actiontoken = Actiontoken.where(key: token_key).take
  if actiontoken.nil?
    res.status = 404
    res.body   = 'token not found'
    next
  end

  # Check if token has expired
  if actiontoken.expired?
    actiontoken.destroy
    res.status = 409
    res.body = 'expired token'
    next
  end

  # Get user with this password reset token
  data = OpenStruct.new(actiontoken.data)
  user = User.where(id: data.model_id).take
  if user.nil?
    actiontoken.destroy
    res.status = 404
    res.body = 'user not found'
    next
  end

  # Reset his password with same salt
  hashed_new_password = Digest::SHA256.hexdigest(user.salt + new_password)
  user.update(password: hashed_new_password)

  # Delete token
  actiontoken.destroy

  res.body = user.to_json
end
server.mount_proc '/user/memberships' do |req, res|
  token = req.header['authorization']

  # Check if a user with this token exists
  user = User.includes(:memberships).find_by token: token
  if user.nil?
    res.status = 404
    res.body   = 'user not found'
    next
  end

  # # Check if user has an active membership
  # active = false
  # user.memberships.each do |membership|
  #   if !membership.expired?
  #     active = true
  #     break
  #   end
  # end
  #
  # if !active
  #   res.status = 403
  #   res.body = 'membership expired'
  #   next
  # end

  res.body = user.memberships.to_json
end
trap "INT" do server.shutdown end
server.start
puts "Started server, listening on port #{port}"
