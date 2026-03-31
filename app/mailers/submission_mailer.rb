class SubmissionMailer < ApplicationMailer
  def status_link(specimen_asset)
    @specimen_asset = specimen_asset
    @status_url = submission_url(specimen_asset.submission_token)

    mail(
      to: specimen_asset.submitter_email,
      subject: "Your specimen submission — #{specimen_asset.display_name}"
    )
  end
end
