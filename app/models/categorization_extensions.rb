module CategorizationExtensions

  extend ActiveSupport::Concern

  included do
    def self.clean_up_sqeel_categorizations(delete: false)
      JobLogger.info("Started method: Categorization.clean_up_sqeel_categorizations")

      Category.where.not(squeel_condition: [nil, '']).*.categorizations.flatten.each do |categorization|
        price = categorization.product.prices.first
        unless price
          categorization.delete if delete
          JobLogger.info(categorization.category.name_de + " <=> " + categorization.product.number + " deleted (price not found)")
          next
        end

        webartikel = MercatorMesonic::Webartikel.find_by(mesokey: price.erp_identifier)
        unless webartikel
          categorization.delete if delete
          JobLogger.info(categorization.category.name_de + " <=> " + categorization.product.number + " deleted (webartikel not found)")
          next
        end

        unless  MercatorMesonic::Webartikel.where{instance_eval(categorization.category.squeel_condition)}.include?(webartikel)
          categorization.delete if delete
          JobLogger.info(categorization.category.name_de + " <=> " + categorization.product.number + " deleted")
        end
      end
      JobLogger.info("Finished method: Categorization.clean_up_sqeel_categorizations")
    end
  end

  # --- Instance Methods --- #
end