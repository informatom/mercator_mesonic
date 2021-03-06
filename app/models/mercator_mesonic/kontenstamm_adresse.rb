module MercatorMesonic
  class KontenstammAdresse < Base

    self.table_name = "T051"
    self.primary_key = "mesoprim"

    attr_accessible :firstname, :lastname, :c001, :c019, :c053, :c116, :c157, :c179, :c180, :c181, :c182, :C241, :c050,
                    :c051, :c052, :c123, :mesocomp, :mesoyear, :mesoprim

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    alias_attribute :street, :c050
    alias_attribute :city, :c052
    alias_attribute :to_hand, :c053
    alias_attribute :postal, :c051
    alias_attribute :land, :c123
    alias_attribute :firstname, :c180
    alias_attribute :lastname, :c181
    alias_attribute :tel_land, :c140
    alias_attribute :tel_city, :c141
    alias_attribute :telephone, :c019
    alias_attribute :fax, :c020
    alias_attribute :email, :c116
    alias_attribute :web , :c128

    validates_presence_of :lastname, :on => :create
    validates_presence_of :street
    validates_presence_of :city
    validates_presence_of :postal

    # --- Instance Methods --- #

    def full_name
      [ self.firstname, self.lastname ].join(" ")
    end

    def telephone_full
      [ self.tel_land, self.tel_city, self.telephone ].join(" ")
    end

    def fax_full
      [ self.tel_land, self.tel_city, self.fax ].join(" ")
    end

    def to_s
      (self.postal or "") + (self.city or "") + "," + (self.street or "")
    end

    #--- Class Methods --- #

    def self.default_order
      :mesoprim
    end

    def self.initialize_mesonic(billing_address: nil, kontonummer: nil)
      self.new(c157: 0, c182: 0, C241: 0,
               c019: billing_address.phone,
               c050: billing_address.street,
               c051: billing_address.postalcode,
               c052: billing_address.city,
               c053: billing_address.detail,
               c123: billing_address.country,
               c179: billing_address.title,
               c180: billing_address.first_name,
               c181: billing_address.surname,
               c001: kontonummer,
               c116: billing_address.email_address.to_s,
               mesocomp: AktMandant.mesocomp,
               mesoyear: AktMandant.mesoyear,
               mesoprim: [kontonummer.to_s, AktMandant.mesocomp, AktMandant.mesoyear.to_s].join("-") )
    end
  end
end