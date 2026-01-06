# app/controllers/specimen_assets_controller.rb
class SpecimenAssetsController < ApplicationController
  def new
    @specimen_asset = SpecimenAsset.new
  end

  def create
    scientific_name = params[:specimen_asset][:scientific_name].to_s.strip

    # Match against GBIF
    gbif_match = GbifClient.match(scientific_name)
    is_good_match = GbifClient.good_match?(gbif_match)

    # Find or create taxon, enriching with GBIF data if available
    taxon = find_or_create_taxon_with_gbif(scientific_name, gbif_match, is_good_match)

    @specimen_asset = taxon.specimen_assets.build(specimen_asset_params)
    @specimen_asset.status = "pending"
    @specimen_asset.needs_review = !is_good_match

    if @specimen_asset.save
      redirect_to root_path, notice: submission_notice(is_good_match)
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    @specimen_asset = SpecimenAsset.new(specimen_asset_params)
    @specimen_asset.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  private

  def specimen_asset_params
    params.require(:specimen_asset).permit(
      :common_name,
      :license,
      :attribution_name,
      :attribution_url,
      :image
    )
  end

  def find_or_create_taxon_with_gbif(scientific_name, gbif_match, is_good_match)
    # Use canonical name from GBIF if available and good match
    canonical = is_good_match && gbif_match ? gbif_match[:canonical_name] : nil
    lookup_name = canonical.presence || scientific_name

    taxon = Taxon.where("LOWER(scientific_name) = LOWER(?)", lookup_name).first

    if taxon
      # Update GBIF data if we have a better match
      if is_good_match && gbif_match && taxon.gbif_key.nil?
        taxon.update(gbif_attributes(gbif_match))
      end
      taxon
    else
      # Create new taxon with GBIF data if available
      attrs = { scientific_name: lookup_name }
      if is_good_match && gbif_match
        attrs.merge!(gbif_attributes(gbif_match))
      end
      Taxon.create!(attrs)
    end
  end

  def gbif_attributes(match)
    {
      taxon_source: "gbif",
      taxon_id: match[:usage_key]&.to_s,
      gbif_key: match[:usage_key],
      gbif_rank: match[:rank],
      gbif_canonical_name: match[:canonical_name],
      gbif_confidence: match[:confidence],
      gbif_match_type: match[:match_type]
    }
  end

  def submission_notice(is_good_match)
    if is_good_match
      "Thank you! Your specimen is pending review and will appear once approved."
    else
      "Thank you! Your specimen is pending review. The scientific name could not be verified and will be checked by a moderator."
    end
  end
end
