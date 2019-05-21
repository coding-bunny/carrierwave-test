class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :name

      t.string :image_filename
      t.string :image_md5

      t.string :image_xsmall_md5
      t.string :image_small_md5
      t.string :image_medium_md5
      t.string :image_large_md5
      t.timestamps
    end
  end
end
