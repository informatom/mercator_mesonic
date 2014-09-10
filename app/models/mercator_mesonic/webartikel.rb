module MercatorMesonic
  class Webartikel < Base

    self.table_name = "WEBARTIKEL"
    self.primary_key = "Artikelnummer"

    has_many :mesonic_prices, :class_name => "Price",
             :foreign_key => "c000", :primary_key => "Artikelnummer"

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

      amount = @webartikel.count
      index = 0
      if @webartikel.any?
        @webartikel.group_by{|webartikel| webartikel.Artikelnummer }.each do |artikelnummer, artikel|
          index = index + 1

          @old_inventories = Inventory.where(number: artikelnummer)
          if @old_inventories
            if @old_inventories.destroy_all # This also deletes the prices!
              ::JobLogger.info("Inventories deleted for Product " + artikelnummer)
            else
              ::JobLogger.error("Deleting Inventory failed: " + @old_inventories.errors.first)
            end
          end

          artikel.each do |webartikel|
            @product = Product.where(number: webartikel.Artikelnummer).first

            if @product
              @product.recommendations.destroy_all
              @product.categorizations.where(category_id: @novelties.id).destroy_all
              @product.categorizations.where(category_id: @discounts.id).destroy_all
              @product.categorizations.where(category_id: @topsellers.id).destroy_all
              if @product.lifecycle.can_reactivate?(User.where(administrator: true).first)  &&
                 @product.lifecycle.reactivate!(User.where(administrator: true).first)
                ::JobLogger.info("Product " + @product.number + " reactivated.")
              else
                ::JobLogger.error("Product " + @product.number + " could not be reactivated!")
              end
            else
              @product = Product.create_in_auto(number: webartikel.Artikelnummer,
                                                title: webartikel.Bezeichnung,
                                                description: webartikel.comment)
            end

            delivery_time =  webartikel.Zusatzfeld5 ? webartikel.Zusatzfeld5 : I18n.t("mercator.on_request")

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
                                       infinite: true,
                                       just_imported: true,
                                       alternative_number: webartikel.AltArtNr1)

            if webartikel.Kennzeichen == "T" &&
               webartikel.Artikelnummer != Constant.find_by_key("shipping_cost_article").value
              @product.topseller = true
              position = @topsellers.categorizations.any? ? @topsellers.categorizations.maximum(:position) + 1 : 1
              @product.categorizations.new(category_id: @topsellers.id, position: position)
            else
              @product.categorizations.where(category_id: @topsellers.id).destroy_all
            end

            if webartikel.Kennzeichen == "N" &&
               webartikel.Artikelnummer != Constant.find_by_key("shipping_cost_article").value
              @product.novelty = true
              position = @novelties.categorizations.any? ? @novelties.categorizations.maximum(:position) + 1 : 1
              @product.categorizations.new(category_id: @novelties.id, position: position)
            else
              @product.categorizations.where(category_id: @novelties.id).destroy_all
            end

            if webartikel.PreisdatumVON && ( webartikel.PreisdatumVON <= Time.now ) &&
               webartikel.PreisdatumBIS && ( webartikel.PreisdatumBIS >= Time.now )
              position = @discounts.categorizations.any? ? @discounts.categorizations.maximum(:position) + 1 : 1
              @product.categorizations.new(category_id: @discounts.id, position: position)
            else
              @product.categorizations.where(category_id: @discounts.id).destroy_all
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

            if webartikel.PreisdatumVON &&
               webartikel.PreisdatumVON <= Time.now &&
               webartikel.PreisdatumBIS &&
               webartikel.PreisdatumBIS >= Time.now
              @price.attributes = { promotion: true, valid_from: webartikel.PreisdatumVON, valid_to: webartikel.PreisdatumBIS}
            else
              @price.attributes = { valid_from: Date.today, valid_to: Date.today + 1.year }
            end

            if @price.save
              ::JobLogger.info("Price for Inventory " + @price.inventory_id.to_s + " saved.")
            else
              ::JobLogger.error("Saving Price failed: " +  @price.errors.first.to_s)
            end

            # ---  recommendations-Handling --- #
            if webartikel.Notiz1.present? && webartikel.Notiz2.present?
              @recommended_product = Product.where(number: webartikel.Notiz1).first
              if @recommended_product
                @product.recommendations.new(recommended_product: @recommended_product,
                                             reason_de: webartikel.Notiz2)
              end
            end

            if @product.save
              ::JobLogger.info("Recommendation for Product " + @product.number + " saved.")
            else
              ::JobLogger.error("Saving Recommendation failed: " +  @product.errors.first.to_s)
            end
          end
          ::JobLogger.info("----- Finished: " + artikelnummer.to_s + " (" +  index.to_s + "/" + amount.to_s + ") -----")
        end
      else
        ::JobLogger.info("No new entries in WEBARTIKEL View, nothing updated.")
      end

      self.remove_orphans(only_old: true)

      ::JobLogger.info("Deprecating products ... ")
      ::Product.deprecate
    end


    def self.remove_orphans(only_old: false)
      ::JobLogger.info("Removing orphans ...")
      if only_old
        @inventories = Inventory.where(just_imported: [false, nil])
      else
        @inventories = Inventory.all
      end
      @inventories.each do |inventory|
        if MercatorMesonic::Webartikel.where(Artikelnummer: inventory.number).count == 0
          if inventory.destroy
            ::JobLogger.info("Deleted Inventory " + inventory.number.to_s)
          else
            ::JobLogger.info("Deleting Inventory failed: " + inventory.errors.first)
          end
        else
          ::JobLogger.info("Inventory " + inventory.number.to_s + " still present in MercatorMesonic::Webartikel.")
        end
      end
      ::JobLogger.info("Resetting new inventories ...")
      Inventory.where(just_imported: true).each do |inventory|
        inventory.update_attributes(just_imported: false)
      end
      ::JobLogger.info("... completed, removing orphans finished.")
    end


    def self.test_connection
      [1,2,3].each do |attempt|
        begin
          self.count # that actually tries to establish a connection
          ::JobLogger.info("Connection to Mesonic database established successfully.")
          puts "further logging goes to Joblog: /log/RAILS_ENV_job.log ..."
          return true
        rescue
          ::JobLogger.fatal("Connection to Mesonic database could not be established! (attempt no." + attempt.to_s + ")")
          puts "FATAL ERROR: Connection to Mesonic database could not be established! (attempt no." + attempt.to_s + ")"
        end
      end

      return false
    end

    def self.non_unique
      group(:Artikelnummer).count.select{ |key,value| value > 1 }.keys
    end

    def duplicates
      article_numbers = []
      non_unique.each do |article_number|
        if where(Artikelnummer: article_number)[0].to_a - where(Artikelnummer: article_number)[1].to_a == []
          article_numbers << article_number
        end
      end
      return article_numbers
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