module UserExtensions

  extend ActiveSupport::Concern

  included do
    attr_accessible :mesonic_kontakte_stamm, :mesonic_kontenstamm, :mesonic_kontenstamm_fakt,
                    :mesonic_kontenstamm_fibu, :mesonic_kontenstamm_adresse

    belongs_to :mesonic_kontakte_stamm, class_name: "MercatorMesonic::KontakteStamm", foreign_key: :erp_account_nr

    belongs_to :mesonic_kontenstamm, class_name: "MercatorMesonic::Kontenstamm", foreign_key: :erp_account_nr
    accepts_nested_attributes_for :mesonic_kontenstamm, allow_destroy: false

    belongs_to :mesonic_kontenstamm_fakt, class_name: "MercatorMesonic::KontenstammFakt", foreign_key: :erp_account_nr
    accepts_nested_attributes_for :mesonic_kontenstamm_fakt, allow_destroy: false

    belongs_to :mesonic_kontenstamm_fibu, class_name: "MercatorMesonic::KontenstammFibu", foreign_key: :erp_account_nr
    accepts_nested_attributes_for :mesonic_kontenstamm_fibu, allow_destroy: false

    belongs_to :mesonic_kontenstamm_adresse, class_name: "MercatorMesonic::KontenstammAdresse", foreign_key: :erp_account_nr
    accepts_nested_attributes_for :mesonic_kontenstamm_adresse, allow_destroy: false
  end

  # --- Instance Methods --- #

  def push_to_mesonic
    @timestamp = Time.now

    @kontonummer    = MercatorMesonic::Kontenstamm.next_kontonummer
    @kontaktenummer = MercatorMesonic::KontakteStamm.next_kontaktenummer

    @mesonic_kontakte_stamm = MercatorMesonic::KontakteStamm.initialize_mesonic(user: self, kontonummer: @kontonummer, kontaktenummer: @kontaktenummer)
    @mesonic_kontenstamm  = MercatorMesonic::Kontenstamm.initialize_mesonic(user: self, kontonummer: @kontonummer, timestamp: @timestamp)
    @mesonic_kontenstamm_fakt = MercatorMesonic::KontenstammFakt.initialize_mesonic(kontonummer: @kontonummer)
    @mesonic_kontenstamm_fibu = MercatorMesonic::KontenstammFibu.initialize_mesonic(kontonummer: @kontonummer)
    @mesonic_kontenstamm_adresse =  MercatorMesonic::KontenstammAdresse.initialize_mesonic(billing_address: self.billing_addresses.first, kontonummer: @kontonummer)

    if [@mesonic_kontakte_stamm, @mesonic_kontenstamm, @mesonic_kontenstamm_adresse,
        @mesonic_kontenstamm_fibu, @mesonic_kontenstamm_fakt ].collect(&:valid?).all?

      # HAS 20140325 Not yet connected to production system, uncomment for persisting erp user date
      #  [@mesonic_kontakte_stamm, @mesonic_kontenstamm, @mesonic_kontenstamm_adresse,
      #    @mesonic_kontenstamm_fibu, @mesonic_kontenstamm_fakt ].collect(&:save?).all?
    end

    self.update(erp_account_nr: User.mesoprim(number: @kontonummer),
                erp_contact_nr: User.mesoprim(number: @kontaktenummer) )
  end
end
