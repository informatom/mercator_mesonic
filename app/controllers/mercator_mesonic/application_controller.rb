module MercatorMesonic
  class ApplicationController < ActionController::Base
    include Hobo::Controller
    hobo_controller

    before_filter :admin_required

    def import
      Delayed::Job.enqueue WebartikelImportJob.new
      redirect_to admin_logentries_path
    end

    def update_business_year
      User.update_business_year()

      # Mesokeys for Prices change, so let's get rid of the old ones ...
      Product.check_price(fix: true)

      # ... and import the new ones
      Webartikel.import(update: "missing")

      flash[:success] = "Business Year updates successfully"
      redirect_to admin_front_path
    end

    private

    def admin_required
      redirect_to user_login_path unless logged_in? && current_user.administrator?
    end

    WebartikelImportJob = Struct.new(:dummy) do
      def perform
        Webartikel.import(update: "changed")
      end
    end
  end
end