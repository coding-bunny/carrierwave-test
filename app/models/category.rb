class Category < ApplicationRecord
  extend CarrierwaveReloadPatch

  mount_uploader :image, CategoryImageUploader, mount_on: :image_filename
  reset_reload_method!

  def image_urls
    image.versions.keys.each_with_object({}) do |key, image_hash|
      image_hash[key] = "/images/catalog/categories/#{id}_#{key}.jpg"
    end
  end
end
