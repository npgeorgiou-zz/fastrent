class User < ActiveRecord::Base
  has_many :memberships, :class_name => 'Membership'
end