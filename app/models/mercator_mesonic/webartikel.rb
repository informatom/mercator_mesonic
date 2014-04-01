module MercatorMesonic
  class Webartikel < Base

    self.table_name = "WEBARTIKEL"
    self.primary_key = "Artikelnummer"

    # --- Class Methods --- #

    def self.import(update: "changed")
      @topsellers = Category.topseller
      @novelties  = Category.novelties
      @discounts  = Category.discounts

      if update == "changed"
        @last_batch = Inventory.maximum(:erp_updated_at)
        @webartikel = Webartikel.where("letzteAend > ?", @last_batch)
      else
        @webartikel = Webartikel.all
      end

      if @webartikel.any?
        @webartikel.group_by{|webartikel| webartikel.Artikelnummer }.each do |artikelnummer, artikel|

          @old_inventories = Inventory.where(number: artikelnummer)
          if ( @old_inventories.destroy_all if @old_inventories )# This also deletes the prices!
            ::JobLogger.info("Inventories deleted for Product " + artikelnummer)
          else
            ::JobLogger.error("Deleting Inventory failed: " + @old_inventories.errors.first)
          end

          artikel.each do |webartikel|
            @product = Product.where(number: webartikel.Artikelnummer).first

            if @product
              @product.recommendations.destroy_all
              @product.categorizations.where(category_id: @novelties.id).destroy_all
              @product.categorizations.where(category_id: @discounts.id).destroy_all
              @product.categorizations.where(category_id: @topsellers.id).destroy_all
              if @product.lifecycle.can_reactivate?(User.where(administrator: true).first)
                if @product.lifecycle.reactivate!(User.where(administrator: true).first)
                  ::JobLogger.info("Product " + @product.number + " reactivated.")
                else
                  ::JobLogger.error("Product " + @product.number + " could not be reactivated!")
                end
              end
            else
              @product = Product.create_in_auto(number: webartikel.Artikelnummer,
                                                title: webartikel.Bezeichnung,
                                                description: webartikel.comment)
            end

            webartikel.Zusatzfeld5 ? delivery_time =  webartikel.Zusatzfeld5 : delivery_time = "Auf Anfrage"

            @inventory = Inventory.new(product_id: @product.id,
                                       number: webartikel.Artikelnummer,
                                       name_de: webartikel.Bezeichnung,
                                       comment_de: webartikel.comment,
                                       weight: webartikel.Gewicht,
                                       charge: webartikel.LfdChargennr,
                                       unit: "Stk.",
                                       delivery_time: delivery_time,
                                       amount: 0,
                                       erp_updated_at: webartikel.letzteAend,
                                       erp_vatline: webartikel.Steuersatzzeile,
                                       erp_article_group: webartikel.ArtGruppe,
                                       erp_provision_code: webartikel.Provisionscode,
                                       erp_characteristic_flag: webartikel.Auspraegungsflag,
                                       infinite: true)

            if webartikel.Kennzeichen = "T"
              @product.topseller = true
              position = 1
              position = @topsellers.categorizations.maximum(:position) + 1 if @topsellers.categorizations.any?
              @product.categorizations.new(category_id: @topsellers.id, position: position)
            end

            if webartikel.Kennzeichen = "N"
              @product.novelty = true
              position = 1
              position = @novelties.categorizations.maximum(:position) + 1 if @novelties.categorizations.any?
              @product.categorizations.new(category_id: @novelties.id, position: position)
            end

            if webartikel.PreisdatumVON && webartikel.PreisdatumVON <= Time.now &&
               webartikel.PreisdatumBIS && webartikel.PreisdatumBIS >= Time.now
              position = 1
              position = @discounts.categorizations.maximum(:position) + 1 if @discounts.categorizations.any?
              @product.categorizations.new(category_id: @discounts.id, position: position)
            end

            if @inventory.save
              ::JobLogger.info("Inventory " + @inventory.number + " saved.")
            else
              ::JobLogger.error("Saving Inventory failed: " + @inventory.errors.first.to_s)
            end

            # ---  Price-Handling --- #
            @price =  Price.new(value: webartikel.Preis,
                                scale_from: webartikel.AbMenge,
                                scale_to: 9999,
                                vat: webartikel.Steuersatzzeile * 10,
                                inventory_id: @inventory.id)

            if webartikel.PreisdatumVON && webartikel.PreisdatumVON <= Time.now &&
               webartikel.PreisdatumBIS && webartikel.PreisdatumBIS >= Time.now
              @price.promotion = true
              @price.valid_from = webartikel.PreisdatumVON
              @price.valid_to = webartikel.PreisdatumBIS
            else
              @price.valid_from = Date.today
              @price.valid_to = Date.today + 1.year
            end

            if @price.save
              ::JobLogger.info("Price for Inventory " + @price.inventory_id.to_s + " saved.")
            else
              ::JobLogger.error("Saving Price failed: " +  @price.errors.first.to_s)
            end

            # ---  recommendations-Handling --- #
            if webartikel.Notiz1.present? && webartikel.Notiz2.present?
              @recommended_product = Product.where(number: webartikel.Notiz1).first
              @product.recommendations.new(recommended_product: @recommended_product,
                                           reason_de: webartikel.Notiz2) if @recommended_product
            end

            if @product.save
              ::JobLogger.info("Recommendation for Product " + @product.number + " saved.")
            else
              ::JobLogger.error("Saving Recommendation failed: " +  @product.errors.first.to_s)
            end
          end
        end
      else
        ::JobLogger.info("No new entries in WEBARTIKEL View, nothing updated.")
      end
    end

    def self.remove_orphans
      Inventory.all.each do |inventory|
        if MercatorMesonic::Webartikel.where(Artikelnummer: inventory.number).count == 0
          if inventory.destroy
            ::JobLogger.info("Deleted Inventory " + inventory.number.to_s)
          else
            ::JobLogger.info("Deleting Inventory failed: " + inventory.errors.first)
          end
        end
      end
    end

    def self.test_connection
      begin
        self.count
        ::JobLogger.info("Connection to Mesonic database established successfully.")
        puts "further logging goes to Joblog: /log/RAILS_ENV_job.log ..."
        return true
      rescue
        ::JobLogger.fatal("Connection to Mesonic database could not be established!")
        puts "FATAL ERROR: Connection to Mesonic database could not be established!"
        return false
      end
    end

    # --- Instance Methods --- #

     def readonly?  # prevents unintentional changes
      true
     end

    def comment
      if self.Langtext1.present?
        return self.Langtext1.to_s + " " + self.Langtext2.to_s
      else
        return self.Langtext2.to_s
      end
    end
  end
end