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

  # GET /taxa/suggest?q=...
  # Returns JSON array of GBIF suggestions for autocomplete
  def suggest
    query = params[:q].to_s.strip
    suggestions = GbifClient.suggest(query, limit: 8)

    render json: suggestions.map { |s|
      {
        key: s[:key],
        name: s[:scientific_name],
        canonical: s[:canonical_name],
        rank: s[:rank]
      }
    }
  end
end
