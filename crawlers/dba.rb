require 'unirest'
require 'json'
require 'colorize'
require 'yaml'
require 'date'

require_relative 'base'
require_relative '../util/string'

class Dba < Base

  def scan
    # Get config options
    config   = YAML.load_file('config/config.yaml').dig('crawlers.dba')
    base_uri = config.dig('base_uri')
    apiKey   = config['apiKey']
    regions  = config.dig('regions')
    types    = config.dig('types')

    # Load zip codes
    zip_codes = load_areas

    # Get new ads
    regions.each do |region|
      regionName = region[0]
      regionId   = region[1]

      types.each do |type|
        typeName = type[0]
        typeId   = type[1]

        # Form uri
        uri = base_uri.replace('regionId', regionId).replace('categoryId', typeId)

        # Get the ads
        puts "Dba: Getting ads for region: #{regionName}, type: #{typeName}"
        response = Unirest.get(
            uri,
            headers:{'DbaApiKey' => apiKey}
        )
        response = JSON.parse(response.raw_body)

        # Delete unnecessary keys
        response.delete('info')
        response.delete('advertising')
        response.delete('tracking')

        ads = response['ads']

        ads.each do |rental|
          rental.delete('pictures')

          zip = rental.dig('ad-address.zip-code')

          # Check if zip is in my csv TODO: send sms if not
          if (!zip_codes.key?(zip))
            puts "#{zip} not in file"
            # next
          end

          # Get date
          posted = rental.dig('insertion-date-time').get_between('(', '+')
          posted = posted.to_i / 1000

          lat = rental.dig('ad-address.latitude')
          lng = rental.dig('ad-address.longitude')

          # If lat and lng is nil, get from csv file
          lat = (lat.nil?) ? zip_codes[zip].lat : lat
          lng = (lng.nil?) ? zip_codes[zip].lng : lng

          # Get size and street from matrixdate
          size   = nil
          street = rental.dig('ad-address.street')
          rental.dig('matrixdata').each do |hash|
            if hash.dig('label') === 'Adresse'
              street = hash.dig('value')
            end

            if hash.dig('label') === 'Boligkvm.'
              size = hash.dig('value')
            end
          end

          # Persist
          ad = Ad.new(
              {
                  region:  zip_codes[zip].region,
                  ad_type: typeName,
                  title:   rental.dig('title')[0...64] || 'No title',
                  text:    rental.dig('description')[0...100],
                  url:     rental.dig('ad-url.href'),
                  posted:  posted,
                  created: Time.now.to_i,
                  rent:    rental.dig('price') || 'Not known',
                  size:    size || 'Not known',
                  zip:     zip,
                  street:  street || 'Not known',
                  city:    rental.dig('ad-address.city') || 'Not known',
                  lat:     lat,
                  lng:     lng,
                  site:    'Dba'
              }
          )

          if Ad.exists?(url: ad.url)
            puts ' -exists'
          else
            puts " -saving #{ad.url}"
            ad.save
          end

          # Ad.exists?(url: ad.url) || ad.save
        end
      end
    end
  end

end