module OrderExtensions

  # --- Instance Methods --- #
  def push_to_mesonic
    mesonic_order = MercatorMesonic::Order.initialize_mesonic(order: self)
    mesonic_order_items = []
    self.linetimes.each_with_index do |lineitiem, index|
      mesonic_order_items << MercatorMesonic::OrderItem.initialize_mesonic(mesonic_order: mesonic_order,
                                                                           lineitem: lineitem,
                                                                           customer: self.user,
                                                                           index: index)
    end

    save_return_value = Order.transaction do
      mesonic_order.save
      mesonic_order_items.collect(&:save)
    end

    if save_return_value
      self.update(erp_customer_number: self.user.erp_account_nr,
                  erp_billing_number: mesonic_order.c021,
                  erp_order_number: mesonic_order.c022)

      Mailer::OrderMailer.deliver_order_confirmation(order: self)
    else
      raise "order could not be pushed to mesonic"
    end
  end

end