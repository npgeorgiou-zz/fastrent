class User < ActiveRecord::Base
  has_many :memberships, :class_name => 'Membership', :dependent => :delete_all
end