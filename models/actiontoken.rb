class Actiontoken < ActiveRecord::Base

  def expired?
    timestamp_self = self.created.to_i
    timestamp_now  = Time.now.to_i

    return timestamp_now > timestamp_self + 60*15
  end
end