require 'data_mapper'
require 'digest/sha2'
require 'pony'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/trd_test")

if ENV['RACK_ENV'] == 'production'
  set :bucket, ENV['S3_BUCKET_NAME']
  set :s3_key, ENV['AWS_ACCESS_KEY_ID']
  set :s3_secret, ENV['AWS_SECRET_ACCESS_KEY']
  set :session_secret, 'manjusri'

  AWS::S3::Base.establish_connection!(
  :access_key_id     => settings.s3_key,
  :secret_access_key => settings.s3_secret)

  set :stripe_key, ENV['STRIPE_SECRET_KEY']

  DataMapper::Model.raise_on_save_failure = false 

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
else
  set :session_secret, 'manjusri'
  set :stripe_key, 'sk_test_aR1DCWnDqi5OlkU04ZyH3tp3'
  DataMapper::Model.raise_on_save_failure = true

  Pony.options = {
    :to => 'Scott Sansovich <ssansovich@gmail.com>',
    :via => :sendmail
  }
end
