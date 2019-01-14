# frozen_string_literal: true

require "mini_magick"

class ImageUploadService
  def initialize(file)
    @file = file
  end

  def call(user)
    image = Image.create!(created_by: user)

    blob = ActiveStorage::Blob.create_after_upload!(
      io: image_normaliser.normalised_file,
      filename: filename,
      content_type: mime_type,
    )

    file_revision = Image::FileRevision.new(
      image_attributes.merge(blob: blob, created_by: user),
    )
    file_revision.ensure_assets

    Image::Revision.create!(
      image: image,
      created_by: user,
      file_revision: file_revision,
      metadata_revision: Image::MetadataRevision.new(created_by: user),
    )
  end

private

  attr_reader :file

  def filename
    file.respond_to?(:original_filename) ? file.original_filename : File.basename(file)
  end

  def mime_type
    @mime_type ||= Marcel::MimeType.for(file)
  end

  def image_normaliser
    @image_normaliser ||= ImageNormaliser.new(file.path)
  end

  def image_attributes
    @image_attributes ||= build_image_attributes
  end

  def build_image_attributes
    dimensions = image_normaliser.dimensions
    cropper = ImageCentreCropper.new(dimensions[:width],
                                dimensions[:height],
                                Image::WIDTH.to_f / Image::HEIGHT)
    {
      width: dimensions[:width],
      height: dimensions[:height],
      crop_x: cropper.dimensions[:x],
      crop_y: cropper.dimensions[:y],
      crop_width: cropper.dimensions[:width],
      crop_height: cropper.dimensions[:height],
      filename: filename,
    }
  end
end
