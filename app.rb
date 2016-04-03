require 'sinatra'
require 'json'
require_relative 'ar.rb'
require_relative 'util/hash'
require 'active_record'
require_relative 'models/user'
require_relative 'models/membership'
require_relative 'models/ad'
require_relative 'models/actiontoken'
require_relative 'handlers/email'

class App < Sinatra::Base

  get '/' do
    File.read('public/views/main.html')
  end

  get '/*' do |path|
    if File.exist?("public/#{path}")
      File.read("public/#{path}")
    else
      halt 404, 'Not found'
    end

  end

  post '/fetch' do
    token   = request.env['HTTP_AUTHORIZATION']
    request.body.rewind
    body    = JSON.parse request.body.read
    site    = body.dig('site')
    region  = body.dig('region')
    type    = body.dig('type')
    minRent = body.dig('minRent')
    maxRent = body.dig('maxRent')
    from    = body.dig('from')

    can_see_urls = false

    # Check if a user with this token exists
    if token != 'null'
      user = User.includes(:memberships).find_by token: token
      if user.nil?
        halt 404, 'No user with these credentials found'
      end

      can_see_urls = user_has_active_membership?(user)
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
    if !can_see_urls
      boligportalAds.each do |ad|
        ad.url = 'hidden'
      end
    end

    return boligportalAds.to_json
  end
  post '/fetch-new' do
    token   = request.env['HTTP_AUTHORIZATION']
    request.body.rewind
    body    = JSON.parse request.body.read
    site    = body.dig('site')
    region  = body.dig('region')
    type    = body.dig('type')
    minRent = body.dig('minRent')
    maxRent = body.dig('maxRent')
    from    = body.dig('from')

    can_see_urls = false

    # Check if a user with this token exists
    if token != 'null'
      user = User.includes(:memberships).find_by token: token
      if user.nil?
        halt 404, 'No user with these credentials found'
      end

      can_see_urls = user_has_active_membership?(user)
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
    if !can_see_urls
      boligportalAds.each do |ad|
        ad.url = 'hidden'
      end
    end

    return boligportalAds.to_json
  end
  post '/user/register' do
    request.body.rewind
    body     = JSON.parse request.body.read
    email    = body.dig('email')
    password = body.dig('password')

    # Check if email is already in database
    if User.exists?(email: email)
      halt 409, 'User with that email already exists'
    end

      # Generate salt
      salt = SecureRandom.hex(32)

      # Append salt to password and hash them
      hashed_pass = Digest::SHA2.hexdigest(salt + password)

      # TODO: Do these 2 operations in a transaction
      # Create user
      user = User.new(
        {
          email:    email,
          password: hashed_pass,
          salt:     salt,
          token:    SecureRandom.hex(32),
          settings: nil,
          created:  Time.now.to_i
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

      return 'OK'
  end
  post '/user/login' do
    request.body.rewind
    body     = JSON.parse request.body.read
    email    = body.dig('email')
    password = body.dig('password')

    # Check if a user with this email exists
    if !User.exists?(email: email)
      halt 409, 'No user with these credentials found'
    end

    # Get user
    user = User.where(email: email).take

    # Append salt to password and hash them
    salt        = user.salt
    hashed_pass = Digest::SHA2.hexdigest(salt + password)

    # Compare
    if (hashed_pass != user.password)
      halt 409, 'No user with these credentials found'
    end

    # Strip private info
    return strip_user_sensitive_info(user).to_json
  end
  post '/user/logout' do
    token = request.env['HTTP_AUTHORIZATION']

    # Check if a user with this token exists
    if token != 'null'
      user = User.includes(:memberships).find_by token: token
      if user.nil?
        halt 404, 'No user with these credentials found'
      end
    end

    return 'OK'
  end
  post '/user/update/settings' do
    token   = request.env['HTTP_AUTHORIZATION']
    request.body.rewind
    new_settings = JSON.parse request.body.read

    # Check if a user with this token exists
    user = User.includes(:memberships).find_by token: token
    if user.nil?
      halt 404, 'User not found'
    end

    # Check if user has an active membership
    if !user_has_active_membership?(user)
      halt 403, 'Membership expired'
    end

    # Update settings
    user.update(settings: new_settings)

    # Strip private info
    return strip_user_sensitive_info(user).to_json
  end
  post '/user/password-request' do
    request.body.rewind
    body  = JSON.parse request.body.read
    email = body.dig('email')

    # Get user with this email
    user = User.where(email: email).take

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
          "Click here in the next 15 mins to set your new password \n http://localhost:3000/#/set-new-password?t=#{actiontoken.key}"
      )
    end

    # Always return OK
    return 'OK'
  end
  post '/user/password-reset' do
    request.body.rewind
    body         = JSON.parse request.body.read
    token_key    = body.dig('token_key')
    new_password = body.dig('new_password')

    if (new_password.nil? || token_key.nil?)
      halt 400, 'Missing input'
    end

    # Get actiontoken
    actiontoken = Actiontoken.where(key: token_key).take
    if actiontoken.nil?
      halt 404, 'Token not found'
    end

    # Check if token has expired
    if actiontoken.expired?
      actiontoken.destroy
      halt 409, 'Expired token'
    end

    # Get user with this password reset token
    data = OpenStruct.new(actiontoken.data)
    user = User.where(id: data.model_id).take
    if user.nil?
      actiontoken.destroy
      halt 404, 'User not found'
    end

    # Reset his password with same salt
    hashed_new_password = Digest::SHA256.hexdigest(user.salt + new_password)
    user.update(password: hashed_new_password)

    # Delete token
    actiontoken.destroy

    return 'OK'
  end
  post '/user/memberships' do
    token   = request.env['HTTP_AUTHORIZATION']

    # Check if a user with this token exists
    user = User.includes(:memberships).find_by token: token
    if user.nil?
      halt 404, 'User not found'
    end

    return user.memberships.to_json
  end
  post '/user/delete' do
    token   = request.env['HTTP_AUTHORIZATION']

    # Check if a user with this token exists
    user = User.includes(:memberships).find_by token: token
    if user.nil?
      halt 404, 'User not found'
    end

    # Delete user and related memberships
    user.destroy
    return 'OK'
  end

  def strip_user_sensitive_info(user)
    return {
        token:    user.token,
        settings: user.settings
    }
  end

  def user_has_active_membership?(user)
    active = false
    user.memberships.each do |membership|
      if !membership.expired?
        active = true
        break
      end
    end

    return active
  end

end
