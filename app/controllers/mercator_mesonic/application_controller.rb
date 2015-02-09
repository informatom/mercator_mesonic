module MercatorMesonic
  class ApplicationController < ActionController::Base
    include Hobo::Controller
    hobo_controller

    before_filter :admin_required

    def import
      Delayed::Job.enqueue WebartikelImportJob.new
      redirect_to admin_logentries_path
    end

    private

    def admin_required
      redirect_to user_login_path unless logged_in? &&  current_user.administrator?
    end

    WebartikelImportJob = Struct.new(:dummy) do
      def perform
        Webartikel.import(update: "changed")
      end
    end
  end
end