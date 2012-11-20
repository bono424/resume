if not ENV['RACK_ENV'].nil?
    CarrierWave.configure do |config|
        config.fog_credentials = {
            :provider               => 'AWS',
            :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
            :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY']
        }
        config.fog_directory  = ENV['S3_BUCKET_NAME']
    end
else
    CarrierWave.configure do |config|
        config.fog_credentials = {
            :provider               => 'AWS',
            :aws_access_key_id      => 'AKIAIQGNVCLXSVJ6JI4Q',
            :aws_secret_access_key  => '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' 
        }
        config.fog_directory  = 'trd-assets'
    end
end
