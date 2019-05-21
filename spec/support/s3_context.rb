RSpec.shared_context 's3' do
  let(:storage) { ShardedS3Storage }
  let(:default_model) { Style.new }
  let(:default_uploader) { S3ImageUploader }
  let(:bucket) { CarrierWave::Uploader::Base.fog_directory }
end
