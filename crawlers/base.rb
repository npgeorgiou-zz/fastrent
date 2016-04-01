
require 'csv'

require_relative '../util/string'

class Base

  def load_areas
    # Load zip codes
    zip_codes = Hash.new()
    CSV.read('data/zip_codes.csv').each do |array|
      zip_codes[array[0].to_i] = OpenStruct.new(
          {
              'code'   => array[0],
              'region' => array[1],
              'name'   => array[2],
              'lat'    => array[3],
              'lng'    => array[4]
          }
      )
    end

    return zip_codes
  end

end