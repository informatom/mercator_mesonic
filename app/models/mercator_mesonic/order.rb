module MercatorMesonic
  class Order < Base

    self.table_name = "T025"
    self.primary_key = "C000"

    attr_accessible :c000, :c004, :c005, :c006, :c007, :c008, :c010, :c011, :c012, :c013, :c014, :c017, :c019,
                    :c020, :c021, :c022, :c023, :c024, :c025, :c026, :c027, :c030, :c034, :c035, :c036, :c037,
                    :c038, :c039, :c040, :c041, :c047, :c049, :c050, :c051, :c053, :c054, :c056, :c057, :c059,
                    :c074, :c075, :c076, :c077, :c078, :c080, :c081, :c082, :c086, :c088, :c089, :c090, :c091,
                    :c092, :c093, :c094, :c095, :c096, :c097, :c098, :c099, :c100, :c102, :c103, :c104, :c105,
                    :c106, :c109, :c111, :c113, :c114, :c115, :c116, :c117, :c118, :c120, :c121, :c123, :c126,
                    :c127, :c137, :c139, :c140, :c141, :c142, :c143, :C151, :C152, :C153, :C154, :C155, :C156,
                    :C157, :C158, :C159, :C160, :mesocomp, :mesoyear, :mesoprim

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    # --- Class Methods --- #

    def self.initialize_mesonic(order: nil, custom_order_number: nil)

      customer = order.user
      timestamp = Time.now
      mesonic_kontenstamm_fakt = customer.mesonic_kontenstamm_fakt
      custom_order_number ||= timestamp.strftime('%y%m%d%H%M%S') + timestamp.usec.to_s # timestamp, if custom order number not provided
      kontonummer = customer.mesonic_kontenstamm.try(:kunde?) ? customer.mesonic_kontenstamm.kontonummer : "09WEB"
      usernummer = customer.erp_contact_nr ? customer.erp_contact_nr : customer.id
      billing_method = order.mesonic_payment_id == 1004 ? mesonic_kontenstamm_fakt.c107 : order.mesonic_payment_id2 #HAS 20140325 FIXME

      billing_state_code = Country.where{(name_de == order.billing_country) | (name_en == order.billing_country)}.first.code
      shipping_state_code = Country.where{(name_de == order.shipping_country) | (name_en == order.shipping_country)}.first.code

      self.new(c000: kontonummer + "-" + custom_order_number,
               c004: order.billing_name,
               c005: order.billing_c_o,
               c006: order.billing_street,
               c007: order.billing_postalcode,
               c008: order.billing_city,
               c010: order.shipping_name,
               c011: order.shipping_c_o,
               c012: order.shipping_street,
               c013: order.shipping_postalcode,
               c014: order.shipping_city,
               c017: billing_state_code,
               c019: shipping_state_code,
               c020: usernummer,
               c021: kontonummer,
               c022: custom_order_number,
               c023: "N", # druckstatus angebot
               c024: "N", # druckstatus auftragsbestätigung
               c025: "N", # durckstatus lieferschein
               c026: "N", # druckstatus faktura
               c027: timestamp, # datum angebot
               c030: customer.mesonic_account_number, #### konto-lieferadresse
               c034: mesonic_kontenstamm_fakt.belegart.c014, # belegart
               c035: mesonic_kontenstamm_fakt.c077, # belegart
               c036: mesonic_kontenstamm_fakt.c065, # vertreternummer
               c037: 0, # nettotage
               c038: 0, # skonto%1
               c039: 0, # skontotage1
               c040: 0, # summenrabatt
               c041: 0, # fw-zeile
               c047: mesonic_kontenstamm_fakt.c066,  # preisliste
               c049: 0, # fw einheit
               c050: 0, # fw-faktor
               c051: billing_method, # ...derived above
               c053: mesonic_kontenstamm_fakt.c122, # kostentraeger
               c054: 400, # kostenstelle
               c056: 0, # skonto%2
               c057: 0, # skontotage2
               c059: timestamp, # datum d. erstanlage
               c074: 0, # kennzeichen f FW-Umrechung
               c075: 0, # flag für Webinterface
               c076: 0, # Dokumenten ID
               c077: 0, # FW-Notierungsflag
               c078: 0, # xml-erweiterung
               c080: 0, # filler
               c081: order.billing_detail,
               c082: order.shipping_detail,
               c086: 0, # teilliefersperre
               c088: 0, # priorität
               c089: order.mesonic_shipping_id,
               c090: 0, # freier text 2
               c091: 0, # freier text 3
               c092: 0, # freier text 4
               c093: 0, # sammelrechnung
               c094: 0, # methode
               c095: 0, # ausprägung 1
               c096: 0, # ausprägung 2
               c097: order.mesonic_payment_id, # Zahlungsart
               c098: 101, # freigabekontrolle angebot
               c099: order.sum_incl_vat, # kumulierter zahlungsbetrag
               c100: order.sum_incl_vat, # endbetrag
               c102: 0, # rohertrag
               c103: timestamp + 3.days, #
               c104: 0, # ansprechpartner rechnungsadresse
               c105: 0, # ansprechpartner lieferadresse
               c106: 0, # fremdwährungskurs
               c109: -1, # kontrakttyp
               c111: 2, # exim durchgeführte änderungen
               c113: kontonummer, # konto rechnungsadresse
               c114: 0, # anzahlungsbetrag
               c115: 101, # freigabekontrolle auftrag
               c116: 101, # freigabekontrolle lieferschein
               c117: 101, # freigabekontrolle faktura
               c118: 0, # euro rohertrag
               c120: 0, # fw-einheit für storno
               c121: 0, # sortierung
               c123: 0, # textkennzeichen konto
               c126: 0, # aktionsplanzeile
               c127: 0, # karenztage
               c137: 2,
               c139: 0,
               c140: 0,
               c141: 0,
               c142: 0,
               c143: 0,
               C151: 8,
               C152: "900001",
               C153: 0,
               C154: 0,
               C155: 0,
               C156: 0,
               C157: 0,
               C158: 0,
               C159: 0,
               C160: 0,
               mesocomp: AktMandant.mesocomp,
               mesoyear: AktMandant.mesoyear,
               mesoprim: [kontonummer, custom_order_number, AktMandant.mesocomp, AktMandant.mesoyear].join("-") )
    end
  end
end