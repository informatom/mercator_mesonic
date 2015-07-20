module MercatorProductExtensions

  extend ActiveSupport::Concern

  included do
    def self.reimport_prices
      Product.active.each_with_index do |product, index|
        puts index.to_s + ": " + product.number
        product.prices.each do |price|
          price.delete
        end
        product.inventories.destroy_all

        MercatorMesonic::Webartikel.where(Preisart: "1")
                                   .where(Artikelnummer: product.number).each do |webartikel|
          @inventory = webartikel.create_inventory(product: product)
          webartikel.create_price(inventory: @inventory)
        end
      end
    end
  end
end