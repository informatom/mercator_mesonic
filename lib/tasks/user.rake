# encoding: utf-8
require "squeel"

namespace :mesonic do
  namespace :addresses do

    # starten als: 'bundle exec rake mesonic:addresses:import'
    # in Produktivumgebungen: 'bundle exec rake mesonic:addresses:import RAILS_ENV=production'
    desc 'Import addresses from Mesonic '
    task :import => :environment do
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
            print "B"
          else
            debugger
          end

          @address = Address.new(user_id: user.id,
                                 name: name,
                                 c_o: @mesonic_address.to_hand,
                                 street: @mesonic_address.street,
                                 postalcode: @mesonic_address.postal,
                                 city: @mesonic_address.city,
                                 country: land)
          if @address.save
            print "A"
          else
            debugger
          end
        else
          puts "Contact " + user.erp_account_nr.to_s + " not found."
        end
      end
    end
  end
end