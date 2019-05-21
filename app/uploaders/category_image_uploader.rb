class CategoryImageUploader < S3ImageUploader
  include Versionable

  def store_dir
    'categories'
  end
end
