CarrierWave.configure do |config|
        config.fog_credentials = {
            :provider               => 'AWS',
            :aws_access_key_id      => 'AKIAIQGNVCLXSVJ6JI4Q',
            :aws_secret_access_key  => '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' 
        }
        config.fog_directory  = 'trd-assets'
        config.fog_public = true
        confif.fog_host = 'https://s3.amazonaws.com'
end
