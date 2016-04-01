require 'unirest'
require 'colorize'
require_relative 'ar.rb'
require_relative 'models/ad'
require 'typhoeus'

# Clean bolibportal
boligportalAds = Ad.where(
    'site = ?',
    ['Boligportal']
)

boligportalAds.each_slice(100) do |array|
  hydra = Typhoeus::Hydra.new
  array.each do |ad|
    request = Typhoeus::Request.new(ad.url, followlocation: false, timeout: 10, connecttimeout: 5)
    request.on_complete do |response|
      if response.code === 404
        puts "#{ad.url} not there, destroying".red
        ad.destroy
      else
        puts "#{ad.url} still valid"
      end
    end
    hydra.queue(request)
  end

  puts 'Running...'
  hydra.run
  puts "Sleepign 1s"
  sleep 1
end

# Clean dba
dbaAds = Ad.where(
    'site = ?',
    ['Dba']
)

dbaAds.each_slice(100) do |array|
  hydra = Typhoeus::Hydra.new
  array.each do |ad|
    request = Typhoeus::Request.new(ad.url, followlocation: false, timeout: 10, connecttimeout: 5)
    request.on_complete do |response|
      if response.code === 301
        puts "#{ad.url} not there, destroying".red
        ad.destroy
      else
        puts "#{ad.url} still valid"
      end
    end
    hydra.queue(request)
  end

  puts 'Running...'
  hydra.run
  puts "Sleepign 1s"
  sleep 1
end

# Clean boligbasen
boligbasenAds = Ad.where(
    'site = ?',
    ['Boligbasen']
)

boligbasenAds.each_slice(100) do |array|
  hydra = Typhoeus::Hydra.new
  array.each do |ad|
    request = Typhoeus::Request.new(ad.url, followlocation: false, timeout: 10, connecttimeout: 5)
    request.on_complete do |response|
      if response.code === 302
        puts "#{ad.url} not there, destroying".red
        ad.destroy
      else
        puts "#{ad.url} still valid"
      end
    end
    hydra.queue(request)
  end

  puts "Running..."
  hydra.run
  puts "Sleepign 1s"
  sleep 1
end

