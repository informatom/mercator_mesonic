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
      Product.active.each_with_index do |product, index|
        product.check_price(index: index, fix: fix)
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

  def check_price(index: 0, fix: false)
    mercator_price = determine_price(amount: 1,
                                     date: Time.now(),
                                     incl_vat: false,
                                     customer_id: User::JOBUSER.id)

    webartikel = MercatorMesonic::Webartikel.where(Artikelnummer: number, Preisart: "1")
                                            .where{(preisdatumVON <= Time.now) & (preisdatumBIS >= Time.now)}
    if webartikel.count == 1
      mesonic_price = webartikel[0].Preis
    else
      mesonic_price = MercatorMesonic::Webartikel.where(Preisart: "1").find_by(Artikelnummer: number).try(:Preis)
    end

    if mesonic_price && (mesonic_price - mercator_price).abs > 0.1
      puts index.to_s + ": " + number + " " + mesonic_price.to_s + " <> " + mercator_price.to_s

      if fix
        prices.each do |price|
          price.update(value: mesonic_price)

          new_mercator_price = determine_price(amount: 1,
                                               date: Time.now(),
                                               incl_vat: false,
                                               customer_id: User::JOBUSER.id).to_s
          puts "updated price " + price.id.to_s + " for product " +   price.inventory.product.number + " to: " + new_mercator_price
        end
      end
    end
  end
end