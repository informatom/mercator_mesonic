module OrderExtensions

  # --- Instance Methods --- #
  def mesonic_payment_id
    {"cash_payment" => '1002', "atm_payment" => '1003', "pre_payment" => '1010', "e_payment" => '1011'}[self.billing_method]
    # further Mesonic ids Nachnahme => '1001'
  end


  def mesonic_payment_id2
    {"1002" => "17", "1003" => "17", "1010" => "19", "1011" => "25" }[self.mesonic_payment_id]
    # "1001" => "17"
  end


  def mesonic_shipping_id
    {"parcel_service_shipment" => '1', "pickup_shipment" => '2'}[self.shipping_method]
  end


  def push_to_mesonic
    @mesonic_order = MercatorMesonic::Order.initialize_mesonic(order: self)
    @mesonic_order_items = []
    self.lineitems.each_with_index do |lineitem, index|
      @mesonic_order_items << MercatorMesonic::OrderItem.initialize_mesonic(mesonic_order: @mesonic_order,
                                                                            lineitem: lineitem,
                                                                            customer: self.user, index: index)
    end

    ::JobLogger.debug(@mesonic_order)
    @mesonic_order_items.each do |mesonic_order_item|
      ::JobLogger.debug(mesonic_order_item)
    end

    if Rails.env == "production"
      @save_return_value = Order.transaction do
        @mesonic_order.save
        @mesonic_order_items.collect(&:save)
      end
    end

    if @save_return_value
      self.update(erp_customer_number: self.user.erp_account_nr,
                  erp_billing_number:  @mesonic_order.c021,
                  erp_order_number:    @mesonic_order.c022)
      OrderMailer.confirmation(order: self).deliver
    else
      raise "Error! Order could not be pushed to mesonic!"
    end
  end
end