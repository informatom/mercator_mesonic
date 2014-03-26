module MercatorMesonic
  class Belegart < Base

    self.table_name = "T357"
    self.primary_key = "C000"

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end
  end
end