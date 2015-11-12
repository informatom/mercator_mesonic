module MercatorProductExtensions

  extend ActiveSupport::Concern

  included do
    def self.reimport_prices
      Product.active.each_with_index do |product, index|
        puts index.to_s + ": " + product.number
        product.reimport_prices()
      end
    end

    def self.check_price(fix: false)
      JobLogger.info("=" * 50)
      JobLogger.info("Started method: Product.check_price")

      Product.active.each_with_index do |product, index|
        product.check_price(index: index, fix: fix)
      end

      Category.reindexing_and_filter_updates

      JobLogger.info("Finished method: Product.check_price")
      JobLogger.info("=" * 50)
    end
  end

  def reimport_prices
    prices.each do |price|
      price.delete
    end
    inventories.destroy_all

    MercatorMesonic::Webartikel.where(Preisart: "1")
                               .where(Artikelnummer: number).each do |webartikel|
      @inventory = webartikel.create_inventory(product: self)
      webartikel.create_price(inventory: @inventory)
    end
  end

  def check_price(index: 0, fix: false)
    prices.each do |price|
      webartikel = MercatorMesonic::Webartikel.find_by(mesokey: price.erp_identifier)
      if webartikel
        if (price.value - webartikel.Preis).abs > 0.1
          puts index.to_s + ": " + self.number + " " + webartikel.Preis.to_s + " <> " + price.value.to_s
          if fix
            price.update(value: webartikel.Preis)
            puts "updated price " + price.id.to_s + " for product " + price.inventory.product.number + " to: " + price.value.to_s
            JobLogger.info("Updated price " + price.id.to_s + " for product " +
                           price.inventory.product.number + " to: " + price.value.to_s)
          end
        end
      else
        puts "webartikel for mesokey " + price.erp_identifier.to_s + " not found!"
        JobLogger.warn("webartikel for mesokey " + price.erp_identifier.to_s + " not found!")
      end
    end
  end
end