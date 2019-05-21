require 'carrierwave/storage/fog'

class ShardedS3Storage < CarrierWave::Storage::Fog
  class File < CarrierWave::Storage::Fog::File
    extend Forwardable

    class NotFound < StandardError; end

    def_delegators :@uploader, :md5, :access_url, :uploader_root

    def md5_path
      ::File.join(uploader_root, md5.to_s, path)
    end

    def url(_options = {})
      ::File.join(access_url, 'catalog', path)
    end

    # The superclass implementation references `@file` which already has an
    # md5 path memoized, so with_md5_path is harmful here.
    def read
      # fail-fast before requesting an incomplete S3 key
      raise NotFound.new("MD5 for file: #{path} was not found.") unless md5.present?

      Rails.logger.info "#### Read with S3 path: #{path}"
      super
    rescue Excon::Errors::Forbidden => exception
      Rails.logger.error "#### Unable to read file with path: #{path}"
      raise exception
    end

    def store(local_file)
      with_md5_path do
        Rails.logger.info "#### Store with S3 path: #{path}"
        super(local_file)
      end
    end

    def delete
      with_md5_path do
        Rails.logger.info "#### Delete with S3 path: #{path}"
        super
      end
        # If an image is not found, we shouldn't interrupt deletion of the
        # mounting model instance so we can fail silently to Rollbar here.
    rescue Excon::Errors::NotFound => exception
      Rollbar.error(exception)
    end

    def exists?
      with_md5_path { super }
    end

    # File.key here includes the md5_path, and File.new *should* generate an md5 path from the db column after cache
    def copy_to(new_path)
      connection.copy_object(@uploader.fog_directory, file.key, @uploader.fog_directory, new_path, acl_header)
      File.new(@uploader, @base, new_path)
    end

    private

    # not thread safe, but shouldn't matter
    def with_md5_path
      original_path = @path
      begin
        @path = md5_path
        yield
      ensure
        @path = original_path
      end
    end

    def file
      with_md5_path { super }
    end
  end

  def store!(new_file)
    File.new(uploader, self, uploader.store_path).tap do |f|
      f.store(new_file)
    end
  end

  def retrieve!(identifier)
    File.new(uploader, self, uploader.store_path(identifier))
  end

  # These two methods are not used; we use the File storage as our cache store.
  # They exist only for completeness of the Storage API.

  def cache!(new_file)
    File.new(uploader, self, uploader.cache_path).tap do |f|
      f.store(new_file)
    end
  end

  def retrieve_from_cache!(identifier)
    File.new(uploader, self, uploader.cache_path(identifier))
  end
end
