module Versionable
  extend ActiveSupport::Concern

  VERSIONS = {
      xsmall: {
          dimensions: [170, 163],
          quality:    80
      },
      small:  {
          dimensions: [250, 240],
          quality:    70
      },
      medium: {
          dimensions: [500, 479],
          quality:    50
      },
      large:  {
          dimensions: [1000, 959],
          quality:    40
      }
  }.freeze

  included do
    include CarrierWave::MiniMagick
    Versionable::VERSIONS.each do |version_name, settings|
      dimensions = settings[:dimensions]
      quality = settings[:quality]
      send(:version, version_name) do
        process resize_to_fit: dimensions
        process quality: quality

        def basename
          "#{super}_#{version_name}"
        end

        def full_filename(for_file)
          parent_name = super(for_file)
          ext         = ::File.extname(parent_name)
          base_name   = parent_name.chomp(ext)
          base_name   = base_name.gsub("#{version_name}_", '')
                            .gsub("_#{version_name}", '')
          [base_name, version_name].compact.join('_') + ext
        end

        def original_version
          model.public_send(mounted_as)
        end

        def original_md5
          model.public_send(mounted_as).md5
        end
      end
    end
  end
end
