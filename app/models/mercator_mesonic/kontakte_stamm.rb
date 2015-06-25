module MercatorMesonic
  class KontakteStamm < Base

    self.table_name = "T045"
    self.primary_key = "mesoprim"

    attr_accessible :c001, :c002, :c003, :c005, :c007, :c009, :c012, :c046,
                    :c039, :id, :c000, :c025, :c033, :c035, :c040, :c042, :c043, :c054,
                    :c059, :c060, :C061, :C069, :mesocomp, :mesoyear, :mesoprim

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    scope :by_email, ->(email) { where(c025: email) }

    alias_attribute :email,:c025
    alias_attribute :kontonummer, :c039
    alias_attribute :account_number ,:c039
    alias_attribute :uid_number, :c038

    belongs_to :kontenstamm,         :class_name => "Kontenstamm",        :foreign_key => 'c039'
    belongs_to :kontenstamm_adresse, :class_name => "KontenstammAdresse", :foreign_key => 'c039'
    belongs_to :kontenstamm_fakt,    :class_name => "KontenstammFakt",    :foreign_key => 'c039'
    belongs_to :kontenstamm_fibu,    :class_name => "KontenstammFibu",    :foreign_key => "c039"

    delegate :kunde?, :interessent?, to: :kontenstamm
    delegate :telephone, :fax, :uid_number, to: :kontenstamm_adresse


    # --- Class Methods --- #

    def self.default_order
      :mesoprim
    end

    def self.next_kontaktenummer
      last_kontaktenummer = self.select(:c000).order(c000: :desc).limit(1).first.c000.to_i
      while kontaktenummer_exists?( last_kontaktenummer )
        last_kontaktenummer += 1
      end
      last_kontaktenummer
    end

    def self.kontaktenummer_exists?(n)
      self.where(c000: n).any?
    end

    def self.initialize_mesonic(user: nil, kontonummer: nil, kontaktenummer: nil, billing_address: nil)
      self.new(c033: 0, c040: 1, c042: 0, c043: 0, c054: 0, c059: 0, c060: 0,
               c035:     I18n.t("activerecord.attributes.user/genders."+ user.gender, locale: :de),
               c001:     user.surname,
               c002:     user.first_name,
               c003:     user.title,
               c005:     billing_address.street,
               c007:     billing_address.postalcode,
               c009:     billing_address.city,
               c012:     billing_address.phone,
               c046:     billing_address.country,
               c039:     kontonummer,
               id:       kontaktenummer,
               c000:     kontaktenummer,
               c025:     user.email_address,
               C061:     kontaktenummer,
               C069:     4,
               mesocomp: AktMandant.mesocomp,
               mesoyear: AktMandant.mesoyear,
               mesoprim: kontaktenummer.to_s + "-" + AktMandant.mesocomp + "-" + AktMandant.mesoyear.to_s)
    end


    # --- Instance Methods --- #
    def full_name
      (self.c001 or "---") + " - " + (self.c002 or "---")
    end

    def to_s
      self.kontonummer + self.full_name
    end
  end
end