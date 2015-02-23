# encoding: utf-8
require "squeel"

namespace :mesonic do
  namespace :users do
    # starten als: bundle exec rake mesonic:users:update_erp_account_nrs RAILS_ENV=production
    desc 'Update erp account nrs via erp contact numbers from Mesonic '
    task :update_erp_account_nrs => :environment do
      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: mesonic:users:update_erp_account_nrs")
      User.update_erp_account_nrs
      ::JobLogger.info("Finished Job: mesonic:users:update_erp_account_nrs")
      ::JobLogger.info("=" * 50)
    end
  end

  namespace :addresses do

    # starten als: bundle exec rake mesonic:addresses:import RAILS_ENV=production
    desc 'Import addresses from Mesonic '
    task :import => :environment do

      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: mesonic:addresses:import")

      if MercatorMesonic::Webartikel.test_connection
        User.where{erp_contact_nr != nil}.all.each do |user|
          user.update(erp_account_nr: user.erp_account_nr[0..-3]+"68",
                      erp_contact_nr: user.erp_contact_nr[0..-3]+"68")
          @mesonic_address = MercatorMesonic::KontenstammAdresse.where(mesoprim: user.erp_account_nr).first
          if @mesonic_address

            name = @mesonic_address.firstname ? @mesonic_address.firstname + " " + @mesonic_address.lastname : @mesonic_address.lastname
            name = name ? name : "Bitte Name aktualisieren!"
            land = @mesonic_address.land ? @mesonic_address.land : "Österreich"

            @billing_address = BillingAddress.new(user_id: user.id,
                                                  name: name,
                                                  c_o: @mesonic_address.to_hand,
                                                  street: @mesonic_address.street,
                                                  postalcode: @mesonic_address.postal,
                                                  city: @mesonic_address.city,
                                                  country: land,
                                                  email_address: @mesonic_address.email)
            if @billing_address.save
              ::JobLogger.info("Saved BillingAddress " + @billing_address.id.to_s)
            else
              ::JobLogger.error("Saving BillingAddress " + @billing_address.name + "failed.")
            end

            @address = Address.new(user_id: user.id,
                                   name: name,
                                   c_o: @mesonic_address.to_hand,
                                   street: @mesonic_address.street,
                                   postalcode: @mesonic_address.postal,
                                   city: @mesonic_address.city,
                                   country: land)
            if @address.save
              ::JobLogger.info("Saved Address " + @address.id.to_s)
            else
              ::JobLogger.error("Saving Address " + @address.name + "failed.")
            end
          else
            ::JobLogger.warn("Contact " + user.erp_account_nr.to_s + " not found.")
          end
        end
      end

      ::JobLogger.info("Finished Job: mesonic:addresses:import")
      ::JobLogger.info("=" * 50)
    end
  end
end