require 'data_mapper'
require 'digest/sha2'
require 'pony'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/trd_test")

if ENV['RACK_ENV'] == 'production'
  set :bucket, ENV['S3_BUCKET_NAME'] || 'trd_assets'
  set :s3_key, ENV['AWS_ACCESS_KEY_ID'] || 'AKIAIQGNVCLXSVJ6JI4Q'
  set :s3_secret, ENV['AWS_SECRET_ACCESS_KEY'] || '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'

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
