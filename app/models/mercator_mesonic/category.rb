module MercatorMesonic
  class Category < Base

    self.table_name = "t309"
    self.primary_key = "mesoprim"

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }


    # --- Instance Methods --- #

    def parent_key
      groups = self.c000.split('-').reverse!
      changed = false
      groups.map! do |group|
        if changed || group == "00000"
          group
        else
          changed = true
          "00000"
        end
      end
      c000 = groups.reverse!.join('-')
    end

    def comment
      # HAS 20130705 Strip plain text from rtf
      #              then replace stuff like \\'fc with \xFC for ü
      c003.gsub(/\\\w+|\{.*?\}|}/,'')
          .gsub(/\\'(\h{2})/){$1.hex.chr}
          .force_encoding("windows-1252")
          .encode("utf-8") if c003
    end

    def readonly?  # prevents unintentional changes
      true
    end
  end
end