module MercatorMesonic
  class Bild < System

    self.table_name = "t022cmp"
    self.primary_key = "c000"

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end
  end
end
