module MercatorMesonic
  class Ersatzartikel < Base

    self.table_name = "t359"
    self.primary_key = :mesokey

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear }

    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end

    # --- Class Methods --- #

    def self.import_relations
      Ersatzartikel.where(c000: Product.all.*.number, c001: Product.all.*.number)
                   .each do |ersatzartikel|
        product         =  Product.find_by(number: ersatzartikel.c000)
        related_product =  Product.find_by(number: ersatzartikel.c001)
        Productrelation.find_or_create_by(product_id: product.id,
                                          related_product_id: related_product.id)
      end
    end
  end
end