module MercatorMesonic
  class Artikelstamm < Base

    self.table_name = "t024"
    self.primary_key = "mesoprim"
    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }

    # --- Class Methods --- #
    def self.invoices_by_account_number(account_number: nil)
      find_by_sql(
        "SELECT t025.C030 AS Konto,
        t025.C032 AS Rechnungsdatum,
        t025.C055 AS Rechnungsnummer,
        t025.C063 AS Bestelltext,
        t026.C003 AS ArtNr,
        t026.C004 AS Bezeichnung,
        t026.C006 AS Menge,
        t026.C007 AS Einzelpreis,
        t026.C031 AS Gesamtpreis
        FROM t024 INNER JOIN (t025 INNER JOIN t026 ON (t025.C021 = t026.C044) AND (t025.C022 = t026.C045))
        ON (t024.C002 = t026.C003) AND (t025.mesoyear = t024.mesoyear) AND (t024.mesocomp = t025.mesocomp)
        WHERE (((t025.C030)='#{account_number}') AND ((t025.C032) Is Not Null) AND ( (t025.C055) Is Not Null) AND ((t025.C026)='D' Or (t025.C026)='*')
        AND ((t025.C137)=2) AND ((t025.mesocomp)='2004') AND ((t026.mesocomp)='2004')
        AND ((Year(t025.C032))>(Year(GetDate())-10)) AND ((t024.C002)=t024.C011))
        ORDER BY t025.C032 DESC, t025.C055;"
      )
    end

    def self.open_shipments_by_account_number(account_number: nil)
      find_by_sql(
        "SELECT t025.c030 AS Konto,
        t025.c029 AS Lieferscheindatum,
        t025.c045 AS Lieferscheinnummer,
        t025.c029 AS Rechnungsdatum,
        t025.c045 AS Rechnungsnummer,
        t025.c063 AS Bestelltext,
        t026.c003 AS ArtNr,
        t026.c004 AS Bezeichnung,
        t026.c006 AS Menge,
        t026.c007 AS Einzelpreis,
        t026.c031 AS Gesamtpreis,
        t024.c002,
        t024.c003
        FROM t024 INNER JOIN (t025 INNER JOIN t026 ON (t025.c022 = t026.c045) AND (t025.c021 = t026.c044))
        ON (t026.c003 = t024.c002) AND (t025.mesoyear = t024.mesoyear) AND (t024.mesocomp = t025.mesocomp)

        WHERE (((t025.c030)='#{account_number}') AND ((t025.c025)='D' Or (t025.c025)='*')
        AND ((t025.c029) Is Not Null) AND ((t025.c045) Is Not Null) AND ((t025.c137)=2) AND ((t025.mesocomp)='2004')
        AND ((t026.mesocomp)='2004') AND ((Year(T025.c029))>(Year(GetDate())-3)) AND ((t025.c055) Is Null)
        AND ((t024.c002)=T024.c011))

        ORDER BY t025.c029 DESC, t025.c045;"
      )
    end

    def self.open_payments_by_account_number(account_number: nil)
      find_by_sql(
      "SELECT t025.c030 AS Konto,
      t025.c028 AS Auftragsdatum,
      t025.c044 AS Auftragsnummer,
      t025.c028 AS Rechnungsdatum,
      t025.c044 AS Rechnungsnummer,
      t025.c063 AS Bestelltext,
      t026.c003 AS ArtNr,
      t026.c004 AS Bezeichnung,
      t026.c006 AS Menge,
      t026.c007 AS Einzelpreis,
      t026.c031 AS Gesamtpreis
      FROM t025 INNER JOIN t026 ON (t025.c022 = t026.c045) AND (t025.c021 = t026.c044)
      WHERE (((t025.c030)='#{account_number}') AND ((t025.c024)='D' Or (t025.c024)='*') AND ((t025.c028) Is Not Null)
      AND ((t025.c044) Is Not Null) AND ((t025.c137)=2) AND ((t025.mesocomp)='2004') AND ((t026.mesocomp)='2004')
      AND ((Year(T025.c028))>(Year(GetDate())-3)) AND ((t025.c055) Is Null) AND ((t025.c045) Is Null))
      ORDER BY t025.c028 DESC, t025.c044;"
      )
    end

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end
  end
end