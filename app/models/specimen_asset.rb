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
  validate :image_content_type

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

  def image_content_type
    return unless image.attached?

    unless image.blob.content_type.in?(%w[image/png image/webp])
      errors.add(:image, "must be PNG or WebP")
    end
  end
end
