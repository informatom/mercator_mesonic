module MercatorMesonic
  class Price < Base

    self.table_name = "T043"
    self.primary_key = :MESOKEY

    scope :mesoyear, -> { where(mesoyear: AktMandant.mesoyear) }
    scope :mesocomp, -> { where(mesocomp: AktMandant.mesocomp) }
    default_scope { mesocomp.mesoyear.where(c002: 3) }

    alias_attribute :price_column, :c013

    # find customer specific price (for a given account_number)
    scope :by_customer, ->(account_number) { where(c003: account_number, c001: "3") }

    scope :for_date, ->(date) { where(" ( ( t043.c004 IS NULL  OR t043.c004 <= ? ) AND ( t043.c005 IS NULL OR t043.c005 >= ? ) )", date, date ) }

    # find customer-group specific price (for a given account_number)
    # customer group is derived by [t054].[c072] aka KontenstammFakt.kundengruppe
    # not used anyways...
    scope :by_group_through_customer, ->(account_number) do
      joins("INNER JOIN [t054] ON [t054].[mesoyear] = #{AktMandant.mesoyear} AND [t054].[mesocomp] = #{AktMandant.mesocomp}")
      .where("[t054].[c112] = ?", account_number).where("[t043].[c003] = CAST([t054].[c072] as varchar(12)) ")
    end

    # Just a guess: via t004 allowed payment types are checked, so better name would be by_payment_type_through_customer
    # not used anyways...
    # Modified for Test: CStr([t004].[c004]) -> ([t004].[c004])
    scope :group, ->(account_number) do
      joins("INNER JOIN [t004] ON [t004].[mesoyear] = #{AktMandant.mesoyear} AND [t004].[mesocomp] = #{AktMandant.mesocomp} " +
            " INNER JOIN [t054] ON [t054].[mesoyear] = #{AktMandant.mesoyear} AND " +
            "[t054].[mesocomp] = #{AktMandant.mesocomp} AND ([t004].[c001] = [t054].[c077])" +
            "	INNER JOIN [t286] ON (#{AktMandant.mesocomp} = [t286].[mesocomp]) AND " +
            "(#{AktMandant.mesoyear} = [t286].[mesoyear]) AND (([t004].[c004]) = [t286].[c000]) ")
      .where("[t054].[c112] = ?", account_number)
    end

    # find customer-group specific price (for a given customer-group-number)
    scope :by_group, ->(group) { where(c003: group, c001: "2") }

    # find regular price
    scope :regular, -> { where(c001: "1") }

    # --- Instance Methods --- #

    def price
      self.c013
    end

    def readonly?  # prevents unintentional changes
      true
    end

    alias :to_s :price
  end
end