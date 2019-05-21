require 'rails_helper'

shared_examples_for 'an s3 image uploader' do
  include_context 's3'
  %i[content_type present?].each do |meth|
    it { is_expected.to respond_to meth }
  end

  describe '#extname' do
    context 'when #file responds to #filename' do
      it 'returns the extension from the file' do
        allow(subject).to receive(:file).and_return(CarrierWave::SanitizedFile.new(file_path('04600.jpg')))
        expect(subject.extname).to eql('.jpg')
      end
    end

    context 'when the filename column is set' do
      it 'returns the extension from the database column' do
        model.public_send(:"#{subject.mounted_as}_filename=", 'foo.png')
        expect(subject.extname).to eql('.png')
      end
    end

    context 'when no filename is available' do
      it 'defaults to .jpg' do
        model.public_send(:"#{subject.mounted_as}_filename=", nil)
        expect(subject.extname).to eql('.jpg')
      end
    end
  end

  describe '#filename' do
    it 'concatenates the basename and extname instead of using the filename from the db' do
      model.public_send(:"#{subject.mounted_as}_filename=", nil)
      expect(subject.filename).to eql(filename)
    end

    it 'keeps the file extension from the db column when a new file is not present' do
      model.public_send(:"#{subject.mounted_as}_filename=", 'foo.gif')
      expect(subject.filename).to eql(filename.gsub('.jpg', '.gif'))
    end

    context 'when the md5 column is missing' do
      it 'returns nil' do
        model.public_send(:"#{subject.mounted_as}_md5=", nil)
        expect(subject.filename).to be_nil
      end
    end
  end

  describe '#md5' do
    it 'returns the md5 from the db column' do
      model.public_send(:"#{subject.mounted_as}_md5=", 'abcdefg')
      expect(subject.md5).to eql('abcdefg')
    end
  end

  describe 's3 interactions' do
    let(:storage) { subject.instance_variable_get('@storage') }
    let(:md5) { '76aa8a81ee92712851d4756aeba78774' }
    let(:file) { CarrierWave::SanitizedFile.new(file_path('04600.jpg')) }

    before do
      storage.connection.directories.create(key: CarrierWave::Uploader::Base.fog_directory)
      model.update_column(:"#{subject.mounted_as}_filename", nil)
      model.update_column(:"#{subject.mounted_as}_md5", nil)
      model.public_send(:"#{subject.mounted_as}=", file)
      model.save
    end

    context 'assigning a new file' do
      it 'sets the filename and md5 columns on the model' do
        expect(model.public_send(:"#{subject.mounted_as}_filename")).to eql(filename)
        expect(model.public_send(:"#{subject.mounted_as}_md5")).to eql(md5)
      end
    end

    context 'removing a file' do
      it 'clears the filename and md5 columns on the model' do
        subject.remove!
        expect(model.public_send(:"#{subject.mounted_as}_filename")).to be_nil
        expect(model.public_send(:"#{subject.mounted_as}_md5")).to be_nil
      end
    end
  end
end
