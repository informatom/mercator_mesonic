module UserExtensions

  extend ActiveSupport::Concern

  included do
    attr_accessible :mesonic_kontakte_stamm, :mesonic_kontenstamm, :mesonic_kontenstamm_fakt,
                    :mesonic_kontenstamm_fibu, :mesonic_kontenstamm_adresse

    belongs_to :mesonic_kontakte_stamm, class_name: "MercatorMesonic::KontakteStamm",
               foreign_key: :erp_contact_nr, primary_key: :mesoprim

    belongs_to :mesonic_kontenstamm, class_name: "MercatorMesonic::Kontenstamm",
               foreign_key: :erp_account_nr, primary_key: :mesoprim
    accepts_nested_attributes_for :mesonic_kontenstamm, allow_destroy: false

    belongs_to :mesonic_kontenstamm_fakt, class_name: "MercatorMesonic::KontenstammFakt",
               foreign_key: :erp_account_nr, primary_key: :mesoprim
    accepts_nested_attributes_for :mesonic_kontenstamm_fakt, allow_destroy: false

    belongs_to :mesonic_kontenstamm_fibu, class_name: "MercatorMesonic::KontenstammFibu",
               foreign_key: :erp_account_nr, primary_key: :mesoprim
    accepts_nested_attributes_for :mesonic_kontenstamm_fibu, allow_destroy: false

    belongs_to :mesonic_kontenstamm_adresse, class_name: "MercatorMesonic::KontenstammAdresse",
               foreign_key: :erp_account_nr, primary_key: :mesoprim
    accepts_nested_attributes_for :mesonic_kontenstamm_adresse, allow_destroy: false


    def self.update_erp_account_nrs
      erp_users = User.where.not(erp_contact_nr: nil)
      erp_users.each {|erp_user| erp_user.update_erp_account_nr}
    end

    def self.update_business_year
      User.all.each { |user| user.update_business_year }
    end
  end

  # --- Instance Methods --- #

  def push_to_mesonic
    @timestamp = Time.now

    @kontonummer    = MercatorMesonic::Kontenstamm.next_kontonummer
    @kontaktenummer = MercatorMesonic::KontakteStamm.next_kontaktenummer

    @mesonic_kontakte_stamm = MercatorMesonic::KontakteStamm.initialize_mesonic(user: self,
                                                                                kontonummer: @kontonummer,
                                                                                kontaktenummer: @kontaktenummer,
                                                                                billing_address: self.billing_addresses.last)
    @mesonic_kontenstamm  = MercatorMesonic::Kontenstamm.initialize_mesonic(user: self,
                                                                            kontonummer: @kontonummer,
                                                                            timestamp: @timestamp,
                                                                            billing_address: self.billing_addresses.last)
    @mesonic_kontenstamm_fakt = MercatorMesonic::KontenstammFakt.initialize_mesonic(kontonummer: @kontonummer,
                                                                                    email: self.email_address)
    @mesonic_kontenstamm_fibu = MercatorMesonic::KontenstammFibu.initialize_mesonic(kontonummer: @kontonummer)
    @mesonic_kontenstamm_adresse =  MercatorMesonic::KontenstammAdresse.initialize_mesonic(billing_address: self.billing_addresses.last,
                                                                                           kontonummer: @kontonummer)

    if Rails.env == "production"
      if [@mesonic_kontakte_stamm, @mesonic_kontenstamm, @mesonic_kontenstamm_adresse,
          @mesonic_kontenstamm_fibu, @mesonic_kontenstamm_fakt ].collect(&:valid?).all?

        [@mesonic_kontakte_stamm, @mesonic_kontenstamm, @mesonic_kontenstamm_adresse,
         @mesonic_kontenstamm_fibu, @mesonic_kontenstamm_fakt ].collect(&:save).all?
      end
    end

    self.update(erp_account_nr: @kontonummer.to_s + "-" + MercatorMesonic::AktMandant::MESOCOMP.to_s + "-" + MercatorMesonic::AktMandant::MESOYEAR.to_s,
                erp_contact_nr: @kontaktenummer.to_s + "-" + MercatorMesonic::AktMandant::MESOCOMP.to_s + "-" + MercatorMesonic::AktMandant::MESOYEAR.to_s)
  end


  def update_mesonic(billing_address: self.billing_addresses.first)
    @mesonic_kontenstamm_adresse = MercatorMesonic::KontenstammAdresse.where(mesoprim: self.erp_account_nr).first

    if Rails.env == "production" && @mesonic_kontenstamm_adresse
      @mesonic_kontenstamm_adresse.update(c019: billing_address.phone,
                                          c050: billing_address.street,
                                          c051: billing_address.postalcode,
                                          c052: billing_address.city,
                                          c053: billing_address.detail,
                                          c123: billing_address.country,
                                          c179: billing_address.title,
                                          c180: billing_address.first_name,
                                          c181: billing_address.surname,
                                          c116: billing_address.email_address.to_s)
    end
  end


  def mesonic_account_number
    self.erp_account_nr.split("-")[0]
  end


  def update_erp_account_nr
    # We want to fix the local database entry for erp_account_nr if someone changed the Account on mesonic side,
    # e.g. if the potential customer ('Interessent') was changed to an actual customer accout.
    if self.erp_contact_nr && !self.mesonic_kontenstamm && self.mesonic_kontakte_stamm
      @mesonic_kontenstamm = MercatorMesonic::Kontenstamm.where(c002: self.mesonic_kontakte_stamm.c039).first

      if self.update(erp_account_nr: @mesonic_kontenstamm.mesoprim)
        ::JobLogger.info("Updated user " + self.id.to_s + "'s erp account number to " + self.erp_account_nr)
      else
        ::JobLogger.error("Error updating user" + self.id.to_s + "'s erp account number")
      end
    end
  end

  def update_business_year
    if erp_account_nr
      self.update(erp_account_nr: erp_account_nr[0..-5] + MercatorMesonic::AktMandant::MESOYEAR.to_s)
    end

    if erp_contact_nr
      self.update(erp_contact_nr: erp_contact_nr[0..-5] + MercatorMesonic::AktMandant::MESOYEAR.to_s)
    end
  end
end