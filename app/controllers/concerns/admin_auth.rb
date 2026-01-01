# app/controllers/concerns/admin_auth.rb
module AdminAuth
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_admin!
  end

  private

  def authenticate_admin!
    admin_password = ENV["ADMIN_PASSWORD"]

    if admin_password.blank?
      if Rails.env.development? || Rails.env.test?
        raise "ADMIN_PASSWORD environment variable is not set. Set it to enable admin access."
      else
        head :service_unavailable
        return
      end
    end

    authenticate_or_request_with_http_basic("Admin") do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, "admin") &&
        ActiveSupport::SecurityUtils.secure_compare(password, admin_password)
    end
  end
end

