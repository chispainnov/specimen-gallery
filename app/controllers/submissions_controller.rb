class SubmissionsController < ApplicationController
  def show
    @specimen_asset = SpecimenAsset.includes(:taxon).find_by!(submission_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Submission not found."
  end
end
