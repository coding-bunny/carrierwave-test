require 'carrierwave_minimagick_quality'

CarrierWave::Uploader::Base.add_config :access_url
CarrierWave::Uploader::Base.add_config :uploader_root
CarrierWave.configure do |cw|
  cw.storage_engines[:sharded_s3_storage] = 'ShardedS3Storage'
  cw.storage              = :sharded_s3_storage
  cw.fog_provider         = 'fog/aws'
  cw.fog_credentials      = {
      provider:              'AWS',
      aws_access_key_id:     ENV['ACCESS_KEY_ID'],
      aws_secret_access_key: ENV['SECRET_ACCESS_KEY'],
      region:                ENV['S3_REGION']
  }
  cw.fog_directory        = ENV['S3_BUCKET']
  cw.access_url           = '/images'
  cw.uploader_root        = 'mms'
end
