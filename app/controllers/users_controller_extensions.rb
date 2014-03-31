module UsersControllerExtensions
  extend ActiveSupport::Concern

  included do
    index_action :invoices_shipments_payments do
      @invoices = MercatorMesonic::Artikelstamm.invoices_by_account_number(account_number: current_user.mesonic_account_number)
                                               .group_by { |line| line.Rechnungsnummer }
      @open_shipments = MercatorMesonic::Artikelstamm.open_shipments_by_account_number(account_number: current_user.mesonic_account_number)
                                                     .group_by { |line| line.Lieferscheinnummer }
      @open_payments = MercatorMesonic::Artikelstamm.open_payments_by_account_number(account_number: current_user.mesonic_account_number)
                                                    .group_by { |line| line.Rechnungsnummer }
    end
  end
end