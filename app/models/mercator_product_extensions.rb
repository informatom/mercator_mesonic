module MercatorProductExtensions

  extend ActiveSupport::Concern

  included do
    def self.reimport_prices
      Product.active.each_with_index do |product, index|
        puts index.to_s + ": " + product.number
        product.reimport_prices()
      end
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
end