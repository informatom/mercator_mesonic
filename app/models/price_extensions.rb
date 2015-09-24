module PriceExtensions

  extend ActiveSupport::Concern

  included do
    def self.find_erp_identifier
      Price.where(erp_identifier: nil).each do |price|
        price.find_erp_identifier
      end
    end
  end

  # --- Instance Methods --- #

  def find_erp_identifier
    webartikel = MercatorMesonic::Webartikel.where(Artikelnummer: inventory.number, Preisart: "1")
    case webartikel.count
    when 1
      self.update(erp_identifier: MercatorMesonic::Webartikel.find_by(Artikelnummer: inventory.number,
                                                                      Preisart: "1")
                                                             .mesokey)
    when 0
      @product = self.inventory.product
      @inventory = self.inventory
      self.delete
      @inventory.delete
      @product.lifecycle.deactivate!(User::JOBUSER) unless @product.inventories.any?
    else
      if self.valid_to == Date.new(9999, 12, 31) # kein Aktionspreis
        if MercatorMesonic::Webartikel.where(Artikelnummer: inventory.number,
                                             Preisart: "1",
                                             PreisdatumBIS: nil).count == 1
          self.update(erp_identifier: MercatorMesonic::Webartikel.find_by(Artikelnummer: inventory.number,
                                                                          Preisart: "1",
                                                                          PreisdatumBIS: nil)
                                                                 .mesokey)
        end
      else # Aktionspreis
        if MercatorMesonic::Webartikel.where(Artikelnummer: inventory.number,
                                             Preisart: "1",
                                             PreisdatumVON: self.valid_from.to_time,
                                             PreisdatumBIS: self.valid_to.to_time).count == 1
          self.update(erp_identifier: MercatorMesonic::Webartikel.find_by(Artikelnummer: inventory.number,
                                                                          Preisart: "1",
                                                                          PreisdatumVON: self.valid_from.to_time,
                                                                          PreisdatumBIS: self.valid_to.to_time)
                                                                 .mesokey)
        end
      end
    end
  end
end