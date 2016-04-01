require 'yaml'
require 'active_record'
require_relative 'util/hash'
require_relative 'models/ad'
require_relative 'models/user'
require_relative 'models/membership'
require_relative 'models/actiontoken'

config = YAML.load_file('config/config.yaml')

environment = ARGV[0]

ActiveRecord::Base.establish_connection(
    :adapter  => 'postgresql',
    :host     => config.dig("db.#{environment}.host"),
    :database => config.dig("db.#{environment}.database"),
    :username => config.dig("db.#{environment}.username"),
    :password => config.dig("db.#{environment}.password"),
)





