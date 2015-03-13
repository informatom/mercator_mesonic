module MercatorMesonic
  class Eigenschaft < Base

    self.table_name = "t070"
    self.primary_key = :mesokey

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end
  end
end
