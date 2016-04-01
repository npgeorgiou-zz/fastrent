class Membership < ActiveRecord::Base
  belongs_to :user

  def expired?
    timestamp_self = self.created.to_i
    timestamp_now  = Time.now.to_i

    return timestamp_now > timestamp_self + 60*60*24*30
  end
end