module MercatorMesonic
  class AktMandant < Base

    self.table_name = "AktMandant"
    self.primary_key = "mesocomp"

    MESOCOMP = self.first.mesocomp
    MESOYEAR = self.first.mesoyear


    # --- Class Methods --- #

    def self.mesocomp
      MESOCOMP
    end

    def self.mesoyear
      MESOYEAR
    end

    def self.mesocomp_and_year
      [MESOCOMP, MESOYEAR]
    end

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end
  end
end