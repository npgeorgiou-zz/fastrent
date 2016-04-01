require 'rest-client'

class Email


def send (to, subject, text)
  RestClient.post "https://api:key-5434aebd8ddc8d84ef64d0b73ed79d3e@api.mailgun.net/v3/sandbox966428d939ad4feea67fedb7c5007a7a.mailgun.org/messages",
                  :from    => "Fast Rent <fastrent.dk@gmail.com>",
                  :to      => to,
                  :subject => subject,
                  :text    => text
end

end