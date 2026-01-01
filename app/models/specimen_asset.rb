# app/models/specimen_asset.rb
class SpecimenAsset < ApplicationRecord
  has_one_attached :image

  STATUSES = %w[pending approved rejected].freeze
  LICENSES = %w[CC0 CC_BY].freeze

  validates :scientific_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :license, inclusion: { in: LICENSES }

  validate :image_attached
  validate :cc_by_requires_attribution
  validate :image_has_transparency_and_size

  before_validation :default_status

  private

  def default_status
    self.status ||= "pending"
    self.license ||= "CC0"
  end

  def image_attached
    errors.add(:image, "must be attached") unless image.attached?
  end

  def cc_by_requires_attribution
    return unless license == "CC_BY"
    errors.add(:attribution_name, "required for CC-BY") if attribution_name.blank?
    errors.add(:attribution_url, "required for CC-BY") if attribution_url.blank?
  end

  def image_has_transparency_and_size
    return unless image.attached?

    blob = image.blob
    return unless blob.content_type.in?(%w[image/png image/webp])

    require "mini_magick"

    file = MiniMagick::Image.read(blob.download)

    if file.width < 512 || file.height < 512
      errors.add(:image, "must be at least 512×512")
    end

    # transparency check (simple & effective)
    # PNG/WebP without alpha should fail
    alpha = file["%[channels]"] # e.g. "rgba"
    unless alpha.to_s.downcase.include?("a")
      errors.add(:image, "must have a transparent background (alpha channel)")
    end
  rescue => e
    errors.add(:image, "could not be processed (#{e.class})")
  end
end
