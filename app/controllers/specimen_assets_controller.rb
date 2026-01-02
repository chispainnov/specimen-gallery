# app/controllers/specimen_assets_controller.rb
class SpecimenAssetsController < ApplicationController
  def new
    @specimen_asset = SpecimenAsset.new
  end

  def create
    # Find or create taxon by scientific name
    taxon = Taxon.find_or_create_by_name(
      params[:specimen_asset][:scientific_name],
      source: params[:specimen_asset][:taxon_source],
      external_id: params[:specimen_asset][:taxon_id]
    )

    @specimen_asset = taxon.specimen_assets.build(specimen_asset_params)
    @specimen_asset.status = "pending"

    if @specimen_asset.save
      redirect_to root_path, notice: "Thank you! Your specimen is pending review and will appear once approved."
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
end
