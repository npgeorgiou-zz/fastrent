require 'active_record'
require_relative 'models/ad'
require_relative 'models/user'
require_relative 'models/membership'
require_relative 'models/actiontoken'

ActiveRecord::Base.establish_connection(
    :adapter  => 'postgresql',
    :database => 'postgres',
    :username => 'postgres',
    :password => 'Teratodes66',
    :host     => 'localhost')





