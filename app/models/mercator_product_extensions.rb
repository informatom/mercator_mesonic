module MercatorProductExtensions

  extend ActiveSupport::Concern

  included do
    def self.reimport_prices
      Product.active.each_with_index do |product, index|
        puts index.to_s + ": " + product.number
        product.reimport_prices()
      end
    end

    def self.check_price
      Product.active.each_with_index do |product, index|
        puts index.to_s + ": " + product.number
        product.check_price()
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

  def check_price
    mercator_price =  product.determine_price(amount: 1,
                                              date: Time.now(),
                                              incl_vat: false,
                                              customer_id: User::JOBUSER.id)
    mesonic_price = MercatorMesonic::Webarikel.find_by(Artikelnummer: number).Preis
    if mesonic_price == mercator_price
      puts "OK"
    else
      puts mesonic_price + " " + mercator_price
  end
end