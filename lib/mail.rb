require 'pony'

if not ENV['SENDGRID_USERNAME'].nil?
    Pony.options = {
        :via => :smtp,
        :via_options => {
            :address => 'smtp.sendgrid.net',
            :port => '587',
            :domain => 'heroku.com',
            :user_name => ENV['SENDGRID_USERNAME'],
            :password => ENV['SENDGRID_PASSWORD'],
            :authentication => :plain,
            :enable_starttls_auto => true
        }
    }
end
