module MercatorMesonic
  class Kontenstamm < Base

    self.table_name = "T055"
    self.primary_key = "mesoprim"

    attr_accessible :c002, :c004, :c003, :c084, :c086, :c102, :c103, :c127, :c069, :c146, :c155, :c156, :c172,
                    :C253, :C254, :mesosafe, :mesocomp, :mesoyear, :mesoprim

    alias_attribute :name, :c003
    alias_attribute :firma, :name
    alias_attribute :kontonummer, :c002

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    # strange one here: gives the last interested customer ....
    scope :interessenten, -> { where("[T055].[mesoprim] LIKE ?", "1I%").select(:c002).order(c002: :desc).limit(1) }

    scope :interessent, -> { where("[T055].[mesoprim] LIKE ?", "1I%") }

    has_one :kontenstamm_adresse, :class_name => "KontenstammAdresse", :foreign_key => "c001", :primary_key => "c002"

    # --- Class Methods --- #
    def self.default_order
      :mesoprim
    end

    def self.next_kontonummer
      last_kontonummer = self.interessenten.first.c002.split("I").last.to_i
      while  kontonummer_exists?( "1I#{last_kontonummer}" )
        last_kontonummer += 1
      end
      "1I#{last_kontonummer}"
    end

    def self.kontonummer_exists?( k )
      self.where(c002: k).any?
    end

    def self.initialize_mesonic(user: nil, kontonummer: nil, timestamp: nil, billing_address: nil)
      self.new(c146: 0, c155: 0, c156: 0, c172: 0, C253: 0, C254: 0, mesosafe: 0,
               c002:     kontonummer,
               c004:     "4",
               c003:     billing_address.company,
               c084:     billing_address.detail,
               c086:     timestamp,
               c102:     kontonummer,
               c103:     kontonummer,
               c127:     "050-",
               c069:     2,
               mesocomp: AktMandant.mesocomp,
               mesoyear: AktMandant.mesoyear,
               mesoprim: kontonummer.to_s + "-" + AktMandant.mesocomp + "-" + AktMandant.mesoyear.to_s)
    end

    # --- Instance Methods --- #

    def kunde?
      self.c004.to_i == 2 # 2... Kunde, 4 ... Interessent
    end

    def interessent?
      !self.kunde?
    end

    def to_s
      self.name
    end
  end
end