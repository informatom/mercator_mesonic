module MercatorMesonic
  class OrderItem < Base

    self.table_name = "T026"
    self.primary_key = "c000"
    attr_accessible :c000, :c003, :c004, :c005, :c006, :c007, :c008, :c009, :c010, :c011, :c012, :c013, :c014,
                    :c015, :c016, :c018, :c019, :c020, :c021, :c022, :c023, :c024, :c025, :c026, :c027, :c031,
                    :c032, :c033, :c034, :c035, :c042, :c044, :c045, :c046, :c047, :c048, :c052, :c054, :c055,
                    :c056, :c057, :c058, :c059, :c060, :c061, :c062, :c063, :c068, :c070, :c071, :c072, :c073,
                    :c074, :c075, :c077, :c078, :c081, :c082, :c083, :c085, :c086, :c087, :c088, :c091, :c092,
                    :c098, :c099, :c100, :c101, :c104, :C106, :C107, :C108, :C109, :mesocomp, :mesoyear, :mesoprim

    belongs_to :inventory, :foreign_key => "C003"

    attr_accessor :cart_item
    attr_accessor :mesonic_order

    # --- Class Methods --- #

    def self.initialize_mesonic(mesonic_order: nil, lineitem: nil, customer: nil, index: nil)
      id = mesonic_order.c000 + "-" + "%06d" % (index + 1 )
      product = lineitem.product
      inventory = product.determine_inventory(amount: lineitem.amount)

      self.new(c000: id,
               c003: lineitem.product_number,
               c004: lineitem.description_de,
               c005: lineitem.amount, # menge bestellt
               c006: lineitem.amount, # menge geliefert
               c007: lineitem.product_price, # einzelpreis
               c008: 0, # zeilenrabatt 1 und 2  #FIXME lineitem.discount_abs ?
               c009: 4002, # erlöskonto
               c010: inventory.erp_vatline, # umsatzsteuer prozentsatz -> Steuersatzzeile
               c011: 1, # statistikkennzeichen
               c012: inventory.erp_article_group, # artikelgruppe
               c013: 0, # liefertage
               c014: inventory.erp_provision_code, # provisionscode
               c015: nil, # colli
               c016: 0, # menge bereits geliefert
               c018: 0, # faktor 1 nach formeleingabe
               c019: 0, # faktor 2 nach formeleingabe
               c020: 0, # faktor 3 nach formeleingabe
               c021: 0, # zeilenrabatt %1
               c022: 0, # zeilenrabatt %2
               c023: 0, # einstandspreis
               c024: nil, # umstatzsteuercode
               c025: mesonic_order.c027, # lieferdatum
               c026: 400, # kostenstelle
               c027: 0, # lieferwoche
               c031: lineitem.value, # gesamtwert
               c032: 0, # positionslevel
               c033: nil, # positionsnummer text
               c034: inventory.weight, # gewicht
               c035: 0, # einstandspreis KZ
               c042: 1, # datentyp
               c044: mesonic_order.c021, # kontonummer
               c045: mesonic_order.c022, # laufnummer
               c046: 99, # vertreternummer
               c047: nil, # prodflag
               c048: mesonic_order.c027.year, # lieferjahr
               c052: 0, # stat. wert
               c054: 0, # bewertungspreis editieren
               c055: inventory.erp_characteristic_flag, #Ausprägungsflag
               c056: customer.mesonic_account_number, # interessentenkontonummer
               c057: 0, # lagerbestand ändern J/N
               c058: 0, # key für dispozeile
               c059: 0, # zeilennummer d kundenauftrags
               c060: 0, # temp gridzeilennumer
               c061: 0, # zeilennummer des auftrages
               c062: 0, # key handels stückliste
               c063: 0, # flag für update ( telesales )
               c068: 1, # lieferantenartikelnummer
               c070: 0, # colli faktor
               c071: 0, # umrechnungsfaktor colli
               c072: 0, # umrechnungsfaktor menge 2
               c073: 1, # preisartenflag
               c074: 0, # flag für aufgeteilte hauptartikel
               c075: 0, # flag v lieferantenlieferung aufteilen
               c077: 0, # preisupdateflag
               c078: index + 1, # zeilennummer (intern)
               c081: 0, # nummer des kontraktpreises
               c082: 0, # menge 2
               c083: lineitem.vat, # Steuersatz in Prozent
               c085: 2, # exim durchgeführt änderungen
               c086: 0, # EURO einstandspreis
               c087: 0, # bnk-prozent
               c088: 0, # ausgebuchte menge
               c091: 0, # textkennzeichen artikel
               c092: 0, # betrag bezugskosten
               c098: 0, # flag reservierung
               c099: 0, # rückstandsmenge
               c100: 0,
               c101: 0,
               c104: 0,
               mesocomp: AktMandant.mesocomp,
               mesoyear: AktMandant.mesoyear,
               mesoprim: [id, AktMandant.mesocomp, AktMandant.mesoyear].join("-"),
               C106: "",
               C107: 0,
               C108: "",
               C109: 0 )
    end
  end
end