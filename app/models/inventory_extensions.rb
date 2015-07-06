module InventoryExtensions

  extend ActiveSupport::Concern

  included do
    has_many :mesonic_prices, :class_name => "MercatorMesonic::Price",
             :foreign_key => "c000", :primary_key => "number"
  end

  # --- Instance Methods --- #

  def mesonic_price(customer_id: nil)
    @customer = User.find(customer_id)
    return nil unless @customer && @customer.erp_account_nr

    @customer_prices = self.mesonic_prices.by_customer(@customer.erp_account_nr)

    if @customer_prices && @customer_prices.any?
      if Constant.find_by_key('import_gross_prices_from_erp').try(:value) == "true"
        return @customer_prices.first.price * 100 / ( 100 + self.prices.first.vat ) # convert to net price
      else
        return @customer_prices.first.price
      end
    else
      return nil
    end

#   HAS 20140407 Was not active in Opensteam!
#    group_prices = self.mesonic_prices.by_group_through_customer(customer.erp_account_nr)
#    return group_prices.first.price if customer_prices.any?
  end
end