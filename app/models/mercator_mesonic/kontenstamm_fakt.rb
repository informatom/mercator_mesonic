module MercatorMesonic
  class KontenstammFakt < Base

    self.table_name = "T054"
    self.primary_key =  "mesoprim"

    attr_accessible :c060, :c062, :c066, :c065, :c068, :c070, :c071, :c072, :c077, :c107, :c108, :c109, :c110, :c111, :c112, :c113, :c120,
                    :c121, :c132, :c133, :c134, :c148, :c149, :c150, :c171, :c183, :C184, :C187, :mesocomp, :mesoyear, :mesoprim

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    scope :by_kontonummer, ->(account_number) { where(c112: account_number) }

    has_one :belegart,       :class_name => "Belegart",    :foreign_key => "c030", :primary_key => "c077"
    has_many :zahlungsarten, :class_name => "Zahlungsart", :foreign_key => "c000", :primary_key => "c077"


    # --- Class Methods --- #

    def self.default_order
      :mesoprim
    end

    def self.initialize_mesonic(kontonummer: nil, email: nil)
      self.new(c060: 0, c062: 0, c068: 0, c070: 0, c071: 0, c072: 0, c108: 0, c109: 0, c110: 0, c111: 0,
               c113: 0, c120: "0", c132: 0, c133: 0, c134: 0, c148: 0, c149: 0, c150: 0, c171: 0, C184: 0,
               c065: 99,
               c066: 3,
               c077: "21",
               c107: "017",
               c112: kontonummer,
               c121: 1,
               c183: 3, # E-Mail Fakkturen
               C187: email,
               mesocomp: AktMandant.mesocomp,
               mesoyear: AktMandant.mesoyear,
               mesoprim: [kontonummer.to_s, AktMandant.mesocomp, AktMandant.mesoyear.to_s].join("-"))
    end


    # --- Instance Methods --- #

    def to_s
      self.c112
    end
  end
end