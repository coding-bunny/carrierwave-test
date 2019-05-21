require 'rails_helper'

describe ShardedS3Storage do
  include_context 's3'

  let(:model) { FactoryBot.create :category, id: 190, image_filename: filename, image_md5: md5 }
  let(:file) { CarrierWave::SanitizedFile.new(file_path('04600.jpg')) }
  let(:file2) { CarrierWave::SanitizedFile.new(file_path('04600_small.jpg')) }
  let(:md5) { '76aa8a81ee92712851d4756aeba78774' }
  let(:filename) { '190.jpg' }
  let(:path) { 'categories/190.jpg' }
  let(:uploader) { model.image }
  let(:storage_instance) { model.image.instance_variable_get('@storage') }
  let(:storage) { described_class }

  before do
    storage_instance.connection.directories.create(key: CarrierWave::Uploader::Base.fog_directory)
  end

  after do
    model.remove_image!
  end

  context 'interacting with S3' do
    before do
      model.update_attributes!(image_md5: md5, image_filename: filename)
      storage_instance.store!(file)
    end

    let(:s3_file) { uploader.file }

    describe '#store!' do
      it 'uploads the file to s3 with MD5 prepended to path' do
        expect(storage_instance.connection.get_object(bucket, s3_file.md5_path).body)
            .to eql(file.read)
      end

      it 'does not include the MD5 in the local path' do
        expect(s3_file.path).to eq(path)
      end

      it 'returns the file size' do
        s3_file.read
        expect(s3_file.size).to eq(4895)
      end
    end

    describe '#retrieve!' do
      it 'retrieves a file from s3 by filename' do
        expect(storage_instance.retrieve!(filename).read).to eql(file.read)
        expect(storage_instance.retrieve!(filename).extension).to eql('jpg')
      end
    end
  end

  describe File do
    subject { model.image.file }

    %i[md5 access_url uploader_root].each do |meth|
      it { is_expected.to respond_to meth }
    end

    describe '#md5' do
      it 'accesses its md5' do
        expect(subject.md5).to eql(md5)
      end
    end

    describe '#md5_path' do
      it 'accesses its md5 path' do
        expect(subject.md5_path).to eql("mms/#{md5}/categories/#{filename}")
      end
    end

    describe '#url' do
      it 'generates the correct public url' do
        expect(subject.url).to eql("/images/catalog/categories/#{filename}")
      end
    end

    describe '#with_md5_path' do
      it 'changes the path for the given block' do
        expect(subject.path).to eql("categories/#{filename}")
        subject.send(:with_md5_path) do
          expect(subject.path).to eql("mms/#{md5}/categories/#{filename}")
        end
        expect(subject.path).to eql("categories/#{filename}")
      end
    end

    describe '#read' do
      let(:s3_file) { ShardedS3Storage::File.new(uploader, storage_instance, path) }

      it 'logs any Forbidden S3 exceptions and reraises the exception' do
        exception = Excon::Errors::Forbidden.new('doh')
        allow(s3_file).to receive(:with_md5_path).and_raise(exception)
        expect(Rails.logger).to receive(:error).with("#### Unable to read file with path: #{path}")
        expect { s3_file.read }.to raise_error(Excon::Errors::Forbidden, 'doh')
      end

      it 'raises a not found exception if the md5 is not set' do
        allow(s3_file).to receive_messages(md5: nil)
        expect { s3_file.read }.to raise_error(ShardedS3Storage::File::NotFound)
      end
    end

    context 'interacting with S3' do
      let!(:s3_file) { storage_instance.store!(file) }

      describe '#store' do
        it 'saves the file' do
          s3_file.store(file2)
          expect(s3_file.read).to eql(file2.read)
        end
      end

      describe '#delete' do
        it 'deletes a file' do
          expect(s3_file).to exist
          s3_file.delete
          expect(s3_file).not_to exist
        end
      end

      describe '#attributes' do
        it { expect(s3_file.attributes).not_to be_blank }
      end
    end
  end
end
