require 'rails_helper'
require 'uploaders/s3_image_uploader_examples'

describe CategoryImageUploader do
  include_context 's3'
  subject { model.image }

  let(:model) { FactoryBot.create :category, id: 190, image_filename: filename, image_md5: md5 }
  let(:filename) { '190.jpg' }
  let(:md5) { 'f75b8179e4bbe7e2b4a074dcef62de95' }

  describe 'base uploader' do
    it_behaves_like 'an s3 image uploader'
  end

  it { expect(subject.store_dir).to eql('categories') }
  it { expect(subject.basename).to eql('190') }

  describe 'versions' do
    subject { model.image.xsmall }

    it { expect(subject.basename).to eql('190_xsmall') }
    it { expect(subject.original_version.basename).to eql('190') }
  end
end
