# app/controllers/specimen_assets_controller.rb
class SpecimenAssetsController < ApplicationController
  def index
    @specimen_assets = SpecimenAsset.where(status: "approved")

    if params[:q].present?
      @specimen_assets = @specimen_assets.where("scientific_name ILIKE ?", "%#{params[:q]}%")
    end

    @specimen_assets = @specimen_assets.order(created_at: :desc)
  end

  def show
    @specimen_asset = SpecimenAsset.where(status: "approved").find_by(id: params[:id])
    head :not_found unless @specimen_asset
  end

  def new
    @specimen_asset = SpecimenAsset.new
  end

  def create
    @specimen_asset = SpecimenAsset.new(specimen_asset_params)
    @specimen_asset.status = "pending"

    if @specimen_asset.save
      redirect_to root_path, notice: "Thank you! Your specimen is pending review and will appear once approved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def specimen_asset_params
    params.require(:specimen_asset).permit(
      :scientific_name,
      :common_name,
      :taxon_source,
      :taxon_id,
      :license,
      :attribution_name,
      :attribution_url,
      :image
    )
  end
end

