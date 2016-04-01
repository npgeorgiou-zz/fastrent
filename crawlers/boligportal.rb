require 'unirest'
require 'json'
require 'colorize'
require 'yaml'
require 'date'

require_relative 'base'
require_relative '../util/string'
require_relative '../util/hash'

class Boligportal < Base

  def scan
    # Get config options
    config      = YAML.load_file('config/config.yaml').dig('crawlers', 'boligportal')
    base_uri    = config.dig('base_uri')
    regions     = config.dig('regions')
    types       = config.dig('types')
    data        = config.dig('data')
    only_newest = false

    # Load zip codes
    zip_codes = load_areas

    # Get new ads
    regions.each do |region|
      regionName = region[0]
      regionId   = region[1]

      types.each do |type|
        typeName = type[0]
        typeId   = type[1]

        page = 1
        loop do
          more_pages = false
          req_data = data.replace('regionId', regionId)
                         .replace('categoryId', typeId)
                         .replace('page', page)
                         .replace('only_newest', only_newest)

          # Get the ads
          puts "Boligportal: Getting ads for region: #{regionName}, type: #{typeName}, page #{page}"

          response = Unirest.post(base_uri, parameters: req_data)
          response = JSON.parse(response.raw_body)
          ads = response['properties']

          if ads.nil? then
            break
          end
          puts " -#{ads.size.to_s}".green
          # sleep 1

          ads.each do |rental|
            zip = rental.dig('jqt_location', 'zipcode').to_i

            # Check if zip is in my csv TODO: send sms if not
            if (!zip_codes.key?(zip))
              puts "#{zip} not in file"
              # next
            end

            # Persist
            url = 'http://www.boligportal.dk' + rental.dig('jqt_adUrl')
            ad = Ad.new(
              {
                region:  zip_codes[zip].region,
                ad_type: typeName,
                title:   rental.dig('jqt_headline')[0...64] || 'No title',
                text:    rental.dig('jqt_adtext')[0...100],
                url:     'http://www.boligportal.dk' + rental.dig('jqt_adUrl'),
                posted:  rental.dig('jqt_creationDate').to_i,
                created: Time.now.to_i,
                rent:    rental.dig('jqt_economy', 'rent').gsub('.', '') || 'Not known',
                size:    rental.dig('jqt_size', 'm2'),
                zip:     zip,
                street:  rental.dig('jqt_location', 'street') || 'Not known',
                city:    rental.dig('jqt_location', 'city') || 'Not known',
                lat:     zip_codes[zip].lat,
                lng:     zip_codes[zip].lng,
                site:    'Boligportal'
              }
            )

            if Ad.exists?(url: url)
              puts ' -exists'
            else
              puts " -saving #{url}"
              ad.save
            end
            # Ad.exists?(url: url) || ad.save

          end

          if ads.size === 50
            page = page + 1
            more_pages = true
          end

          break if more_pages === false
        end
      end
    end
  end
end