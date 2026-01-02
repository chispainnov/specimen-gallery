# app/controllers/admin/specimen_assets_controller.rb
module Admin
  class SpecimenAssetsController < ApplicationController
    include AdminAuth

    ALLOWED_STATUSES = %w[approved rejected].freeze

    def index
      @specimen_assets = SpecimenAsset.where(status: "pending").order(created_at: :desc)
    end

    def update
      @specimen_asset = SpecimenAsset.find(params[:id])
      new_status = params[:status]

      unless ALLOWED_STATUSES.include?(new_status)
        head :unprocessable_entity
        return
      end

      if @specimen_asset.update(status: new_status)
        redirect_back fallback_location: admin_specimen_assets_path,
                      notice: "Specimen #{new_status}."
      else
        redirect_back fallback_location: admin_specimen_assets_path,
                      alert: "Failed to update: #{@specimen_asset.errors.full_messages.join(', ')}"
      end
    end

    def destroy
      @specimen_asset = SpecimenAsset.find(params[:id])
      @specimen_asset.destroy
      redirect_back fallback_location: admin_specimen_assets_path,
                    notice: "Specimen deleted."
    end
  end
end
