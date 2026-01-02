# app/controllers/taxa_controller.rb
class TaxaController < ApplicationController
  def index
    @taxa = Taxon.with_approved_assets

    if params[:q].present?
      @taxa = @taxa.where("scientific_name ILIKE ?", "%#{params[:q]}%")
    end

    @taxa = @taxa.order(:scientific_name)
  end

  def show
    @taxon = Taxon.find(params[:id])
    @specimen_assets = @taxon.approved_assets

    if @specimen_assets.empty?
      head :not_found
    end
  end
end

