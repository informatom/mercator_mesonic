module MercatorMesonic
  class Webartikel < Base

    self.table_name = "WEBARTIKEL"
    self.primary_key = "Artikelnummer"

    has_many :mesonic_prices, :class_name => "Price",
             :foreign_key => "c000", :primary_key => "Artikelnummer"

    # --- Class Methods --- #

    def self.import(update: "changed")
      @jobuser = User.find_by(surname: "Job User")

      if update == "changed"
        @last_batch = [Inventory.maximum(:erp_updated_at), Time.now - 1.day].min
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
          @old_inventories.destroy_all if @old_inventories # This also deletes the prices!

          artikel.each do |webartikel|
            @product = Product.find_by(number: webartikel.Artikelnummer)

            if @product
              @product.recommendations.destroy_all

              if @product.state == "deactivated"
                @product.lifecycle.reactivate!(@jobuser) or
                (( JobLogger.error("Product " + @product.id.to_s + " could not be reactivated!") ))
              end
            else
              @product = Product.create_in_auto(number: webartikel.Artikelnummer,
                                                title: webartikel.Bezeichnung,
                                                description: webartikel.comment) or
              (( JobLogger.error("Product " + @product.number + " could not be created!") ))
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

            webartikel.update_topseller(product: @product)
            webartikel.update_novelty(product: @product)
            webartikel.update_discount(product: @product)
            webartikel.create_categorization(product: @product)

            @inventory.save or
            (( JobLogger.error("Saving Inventory failed: " + @inventory.errors.first.to_s) ))

            # ---  Price-Handling --- #
            @price =  Price.new(value: webartikel.Preis,
                                scale_from: webartikel.AbMenge,
                                scale_to: 9999,
                                vat: webartikel.Steuersatzzeile * 10,
                                inventory_id: @inventory.id)

            if webartikel.PreisdatumVON && webartikel.PreisdatumVON <= Time.now &&
               webartikel.PreisdatumBIS && webartikel.PreisdatumBIS >= Time.now
              @price.attributes = { promotion: true, valid_from: webartikel.PreisdatumVON, valid_to: webartikel.PreisdatumBIS}
            else
              @price.attributes = { valid_from: Date.today, valid_to: Date.today + 1.year }
            end

            @price.save or
            (( JobLogger.error("Saving Price failed: " +  @price.errors.first.to_s) ))

            # ---  recommendations-Handling --- #
            if webartikel.Notiz1.present? && webartikel.Notiz2.present?
              @recommended_product = Product.where(number: webartikel.Notiz1).first
              if @recommended_product
                @product.recommendations.new(recommended_product: @recommended_product,
                                             reason_de: webartikel.Notiz2)
              end
            end

            @product.save or
            (( JobLogger.error("Saving Product failed: " +  @product.errors.first.to_s)) and debugger)
          end
        end
      else
        puts "No new entries in WEBARTIKEL View, nothing updated."
      end

      self.remove_orphans(only_old: true)
      Product.deprecate
      Category.reindexing_and_filter_updates
    end


    def self.remove_orphans(only_old: false)
      if only_old
        @inventories = Inventory.where(just_imported: [false, nil])
      else
        @inventories = Inventory.all
      end
      @inventories.each do |inventory|
        if Webartikel.where(Artikelnummer: inventory.number).count == 0
          inventory.destroy or
          (( JobLogger.error("Deleting Inventory failed: " + inventory.errors.first) ))
        end
      end

      Inventory.where(just_imported: true).each do |inventory|
        inventory.update_attributes(just_imported: false) or
        (( JobLogger.error("Resetting new inventory" + inventory.id.to_s + "failed!") ))
      end
    end

# Usage for console: MercatorMesonic::Webartikel.test_connection
    def self.test_connection
      start_time = Time.now
      puts "Stop watch started ..."
      [1,2,3,4,5].each do |attempt|
        begin
          self.count # that actually tries to establish a connection
          delta = Time.now - start_time
          puts "Connection established within " + delta.to_s + " seconds"
          JobLogger.info("Connection to Mesonic database established successfully.")
          return true
        rescue
          JobLogger.fatal("Mesonic database connection error (#" + attempt.to_s + ")")
          puts "FATAL ERROR: Mesonic database connection error (#" + attempt.to_s + ")"
        end
      end

      return false
    end

    def self.non_unique
      group(:Artikelnummer).count.select{ |key,value| value > 1 }.keys
    end

    def self.duplicates
      article_numbers = []
      non_unique.each do |article_number|
        if where(Artikelnummer: article_number)[0].attributes.to_a - where(Artikelnummer: article_number)[1].attributes.to_a == []
          article_numbers << article_number
        end
      end
      return article_numbers
    end

    def self.differences
      non_unique.each do |article_number|
        JobLogger.info(article_number + ": " +
                       where(Artikelnummer: article_number)[0].different_attributes(where(Artikelnummer: article_number)[1]).to_s)
      end
    end

    def self.count_aktionen
      self.where{|w| ( w.PreisdatumVON <= Time.now) & (w.PreisdatumBIS >= Time.now)}.count
    end

    def self.update_categorizations
      Categorization.all.delete_all
      Webartikel.all.each do |webartikel|
        product = Product.find_by(number: webartikel.Artikelnummer) or
        (( JobLogger.error("Product not found " + webartikel.Artikelnummer) ))

        webartikel.update_topseller(product: product)
        webartikel.update_novelty(product: product)
        webartikel.update_discount(product: product)
        webartikel.create_categorization(product: product)
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

    def update_topseller(product: nil)
      topsellers = Category.topseller
      product.categorizations.where(category_id: topsellers.id).destroy_all
      if self.Kennzeichen == "T" && self.Artikelnummer != Constant.find_by(key: "shipping_cost_article").value
        product.topseller = true
        position =  topsellers.categorizations.any? ? topsellers.categorizations.maximum(:position) + 1 : 1
        product.categorizations.new(category_id: topsellers.id, position: position)
      else
        product.topseller = false
      end
    end

    def update_novelty(product: nil)
      novelties = Category.novelties
      product.categorizations.where(category_id: novelties.id).destroy_all
      if self.Kennzeichen == "N" && self.Artikelnummer != Constant.find_by(key: "shipping_cost_article").value
        product.novelty = true
        position = novelties.categorizations.any? ? novelties.categorizations.maximum(:position) + 1 : 1
        product.categorizations.new(category_id: novelties.id, position: position)
      else
        product.novelty = false
      end
    end

    def update_discount(product: nil)
      discounts  = Category.discounts
      product.categorizations.where(category_id: discounts.id).destroy_all
      if self.PreisdatumVON && ( self.PreisdatumVON <= Time.now ) &&
         self.PreisdatumBIS && ( self.PreisdatumBIS >= Time.now )
        position = discounts.categorizations.any? ? discounts.categorizations.maximum(:position) + 1 : 1
        product.categorizations.new(category_id: discounts.id, position: position)
      end
    end

    def create_categorization(product:nil)
      unless category = Category.find_by(erp_identifier: self.Artikeluntergruppe)
        JobLogger.info("Product " + product.number + " misses category " + self.Artikeluntergruppe.to_s ) and return ))
        category = Category.auto
      end
      position = category.categorizations.any? ? category.categorizations.maximum(:position) + 1 : 1
      unless product.categorizations.where(category_id: category.id).any?
        product.categorizations.new(category_id: category.id, position: position)
      end
    end
  end
end