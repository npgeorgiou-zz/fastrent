environment = ARGV[0]
if environment != 'development' && environment != 'production'
  raise "Specify either 'development' or 'production' as script argument"
end

require_relative 'crawlers/boligportal'
require_relative 'crawlers/dba'
require_relative 'crawlers/boligbasen'

require_relative 'ar.rb'
require_relative 'models/ad'

# Scan bolibportal
Boligportal.new().scan

# Scan dba
Dba.new().scan

# Scan boligabsen
Boligbasen.new().scan


