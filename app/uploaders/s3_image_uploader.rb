class S3ImageUploader < CarrierWave::Uploader::Base
  extend Forwardable

  storage :sharded_s3_storage
  def_delegators :file, :content_type, :present?

  # Maintain the state of our db columns when changes are made
  after :cache, :update_md5_column
  before :remove, :clear_md5_column
  before :remove, :clear_filename_column

  # The auto-generated basename of our file
  def basename
    model.id.to_s
  end

  # The extension of the given file
  def extname
    return ::File.extname(file.filename) if file && !file.is_a?(ShardedS3Storage::File)

    current_extname = ::File.extname(model.public_send(:"#{mounted_as}_filename").to_s)
    current_extname = ::File.extname(original_filename.to_s) unless current_extname.present?

    return '.jpg' unless current_extname.present?

    current_extname
  end

  # A combination of our extension and the auto-generated basename, or nil
  # if the file doesn't exist
  def filename
    return unless md5.present?

    basename + extname
  end

  # We delegate the md5 to our model, and use its presence as the determinant of existence
  def md5
    model.public_send(md5_column)
  end

  private

  def update_md5_column(new_file)
    model.public_send(:"#{md5_column}=", Digest::MD5.hexdigest(new_file.read))
  end

  def clear_md5_column
    model.public_send(:"#{md5_column}=", nil) unless model.destroyed?
  end

  def clear_filename_column
    model.public_send(:"#{mounted_as}_filename=", nil) unless model.destroyed?
  end

  def md5_column
    [mounted_as, version_name, 'md5'].compact.join('_').to_sym
  end
end
