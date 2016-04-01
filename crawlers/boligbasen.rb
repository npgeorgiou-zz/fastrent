require 'unirest'
require 'json'
require 'colorize'
require 'yaml'
require 'date'
require 'open-uri'
require 'nokogiri'
require 'typhoeus'

require_relative 'base'
require_relative '../util/string'

class Boligbasen < Base

  def scan
    # Get config options
    config   = YAML.load_file('config/config.yaml').dig('crawlers', 'boligbasen')
    base_uri = config.dig('base_uri')

    # Load zip codes
    zip_codes = load_areas

    # Group together identical area names
    areas = Hash.new()
    zip_codes.each do |zip, os|
      if !areas.key?(os.name)
        areas[os.name] = []
      end

      areas[os.name] << os
    end

    chunks = areas.chunk(5)
    chunks.each do |chunk|
      hydra = Typhoeus::Hydra.new
      chunk.each do |hash|

        hash.each do |key, array|

          zip_min = array.first.code
          zip_max = array.last.code
          region  = array.first.region
          city    = array.first.name
          lat     = array.first.lat
          lng     = array.first.lng

          uri = base_uri.replace('zip_min', zip_min).replace('zip_max', zip_max)
          puts "Boligbasen: Buildying LIST request for zip: #{zip_min} to zip: #{zip_max}"
          request = Typhoeus::Request.new(uri, followlocation: true, timeout: 10, connecttimeout: 5)
          request.on_complete do |response|
            puts 'got LIST response'
            doc = Nokogiri::HTML(response.body)
            ads = doc.css('table.boligannonce')
            ads.each do |ad|
              if ad.css('img.semeredk').empty?
                next
              end

              # Get internal ad url TODO: check db existence here
              internal_url = 'http://boligbasen.dk/' + ad.css('a')[0]['href']
              puts "Boligbasen: Buildying PAGE request for: #{internal_url}"
              internal_ad_request = Typhoeus::Request.new(internal_url, timeout: 10, connecttimeout: 5)
              hydra.queue internal_ad_request
              internal_ad_request.on_complete do |response|
                puts 'got PAGE response'
                internal_ad_page = Nokogiri::HTML(response.body)
                ad_table = internal_ad_page.css("table [cellpadding='6']")

                title  = ad_table.css('h1')[0].text
                posted = Time.now.to_i

                ad_deeper_table = ad_table.css("table [class='style1']")
                size    = ad_deeper_table.css('tr')[1].css('td')[2].text.split(' ')[0]
                rent    = ad_deeper_table.css('tr')[2].css('td')[2].text.split(' ')[0].gsub('.', '')
                deposit = ad_deeper_table.css('tr')[3].css('td')[2].text.split(' ')[0]

                ad_type = nil
                street  = nil
                created = Time.now.getutc
                site    = 'Boligbasen'

                if ['Lejlighed'].any? { |word| title.include?(word) }
                  ad_type = 'Appartment'
                end

                if ['Villa', 'Delebolig', 'hus', 'Landejendom'].any? { |word| title.include?(word) }
                  ad_type = 'House'
                end

                if ['Værelse'].any? { |word| title.include?(word) }
                  ad_type = 'Room'
                end

                puts
                puts title || 'Not known'
                puts ad_type
                puts posted
                puts size || 'Not known'
                puts rent || 'Not known'
                puts deposit || 'Not known'
                puts region
                puts zip_min
                puts city
                puts lat
                puts lng

                puts

                # Persist
                ad = Ad.new(
                    {
                        region:  region,
                        ad_type: ad_type,
                        title:   title,
                        text:    nil,
                        url:     internal_url,
                        posted:  posted,
                        created: Time.now.to_i,
                        rent:    rent,
                        size:    size,
                        zip:     zip_min,
                        street:  nil,
                        city:    city,
                        lat:     lat,
                        lng:     lng,
                        site:    site
                    }
                )

                if Ad.exists?(url: ad.url)
                  puts ' -exists'
                else
                  puts " -saving #{ad.url}"
                  ad.save
                end

              end
            end
          end
          hydra.queue(request)
        end
      end
      puts 'running...'
      hydra.run
      puts 'sleeping 1 s...'
      sleep 1
    end

    # areas.each do |area_name, array|
    #   zip_min = array.first.code
    #   zip_max = array.last.code
    #   region  = array.first.region
    #   city    = array.first.name
    #   lat     = array.first.lat
    #   lng     = array.first.lng
    #
    #   uri = base_uri.replace('zip_min', zip_min).replace('zip_max', zip_max)
    #   puts uri
    #   puts "Boligbasen: Getting ads for zip: #{zip_min} to zip: #{zip_max}"
    #
    #   doc = Nokogiri::HTML(open(uri))
    #   ads = doc.css('table.boligannonce')
    #
    #   ads.each do |ad|
    #     if ad.css('img.semeredk').empty?
    #       next
    #     end
    #
    #     # Get internal ad url
    #     url = 'http://boligbasen.dk/' + ad.css('a')[0]['href']
    #
    #     internal_ad_page = Nokogiri::HTML(open(url))
    #     ad_table = internal_ad_page.css("table [cellpadding='6']")
    #
    #     title  = ad_table.css('h1')[0].text
    #     posted = Time.now.getutc
    #
    #     ad_deeper_table = ad_table.css("table [class='style1']")
    #     size    = ad_deeper_table.css('tr')[1].css('td')[2].text.split(' ')[0]
    #     rent    = ad_deeper_table.css('tr')[2].css('td')[2].text.split(' ')[0]
    #     deposit = ad_deeper_table.css('tr')[3].css('td')[2].text.split(' ')[0]
    #
    #     ad_type = nil
    #     street  = nil
    #     created = Time.now.getutc
    #     site    = 'Boligbasen'
    #
    #
    #
    #
    #     if ['Lejlighed'].any? { |word| title.include?(word) }
    #       ad_type = 'Appartment'
    #     end
    #
    #     if ['Villa', 'Delebolig', 'hus'].any? { |word| title.include?(word) }
    #       ad_type = 'House'
    #     end
    #
    #     if ['Værelse'].any? { |word| title.include?(word) }
    #       ad_type = 'Room'
    #     end
    #
    #
    #     puts
    #     puts title
    #     puts ad_type
    #     puts posted
    #     puts size
    #     puts rent
    #     puts deposit
    #     puts region
    #     puts zip_min
    #     puts city
    #     puts lat
    #     puts lng
    #
    #     puts
    #   end
    # end
  end

end