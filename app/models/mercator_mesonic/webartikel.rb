module MercatorMesonic
  class Webartikel < Base

    self.table_name = "WEBARTIKEL"
    self.primary_key = "Artikelnummer"

    has_many :mesonic_prices, :class_name => "Price",
             :foreign_key => "c000", :primary_key => "Artikelnummer"


    # --- Class Methods --- #

    def self.import(update: "changed")
      JobLogger.info("=" * 50)

      #HAS:20150720, Preisart 2,3 are userspecific prices, so we take only Preisart "1"

      if update == "changed"
        JobLogger.info("Started Job: webartikel:update")
        @last_batch = [Inventory.maximum(:erp_updated_at), Time.now - 1.day].min
        @webartikel = Webartikel.where("letzteAend > ?", @last_batch).where(Preisart: "1")
        @webartikel += Webartikel.where("Erstanlage > ?", @last_batch).where(Preisart: "1")
        JobLogger.info(@webartikel.count.to_s + " Products to be updated ...")

      elsif update == "missing"
        JobLogger.info("Started Job: webartikel:missing")
        @webartikel = Webartikel.where(Preisart: "1")
        productnumbers = Inventory.pluck("number")
        @webartikel = @webartikel.find_all{ |webartikel| !productnumbers.include?(webartikel.Artikelnummer) }
        JobLogger.info(@webartikel.count.to_s + " Products missing ...")
      else
        JobLogger.info("Started Job: webartikel:import")
        @webartikel = Webartikel.where(Preisart: "1")
        JobLogger.info(@webartikel.count.to_s + " Products to be updated ...")
      end

      unless @webartikel.any?
        JobLogger.info( "No new entries in WEBARTIKEL View, nothing updated.") and return
      end

      @webartikel.group_by{|webartikel| webartikel.Artikelnummer }.each do |artikelnummer, artikel|

        Inventory.where(number: artikelnummer).destroy_all # This also deletes the prices!

        artikel.each do |webartikel|
          @product = webartikel.import_and_return_product
          if @product.save
            JobLogger.info("Saving Product " + @product.id.to_s + " " +
                            @product.number + " succeeded.")
          else
            JobLogger.error("Saving Product " + @product.number +
                            " failed: " +  @product.errors.first.to_s)
          end
        end
      end

      self.remove_orphans(only_old: true)
      Product.deprecate

      ::Category.reactivate
      ::Category.reindexing_and_filter_updates

      JobLogger.info("Finished Job: webartikel:import")
      JobLogger.info("=" * 50)
    end


    def self.remove_orphans(only_old: false, just_test: false)
      JobLogger.info("=" * 50)
      JobLogger.info("Started Job: webartikel:remove_orphans")

      if only_old
        @inventories = Inventory.where(just_imported: [false, nil])
      else
        @inventories = Inventory.all
      end
      @inventories.each do |inventory|
        if Webartikel.where(mesokey: inventory.prices.*.erp_identifier).count == 0
          JobLogger.info("Deleting Inventory: " + inventory.id.to_s + " , mesokey: " + inventory.prices[0].erp_identifier.to_s)
          unless just_test == true
            inventory.destroy \
            or JobLogger.error("Deleting Inventory failed: " + inventory.errors.first.to_s)
          end
        end
      end

      Inventory.where(just_imported: true).each do |inventory|
        inventory.update_attributes(just_imported: false) \
        or JobLogger.error("Resetting new inventory" + inventory.id.to_s + "failed!")
      end

      JobLogger.info("Finished Job: webartikel:remove_orphans")
      JobLogger.info("=" * 50)
    end


    # Usage from rails console: MercatorMesonic::Webartikel.test_connection
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
      # returns identical entries (all attribut values ore the same)
      article_numbers = []
      non_unique.each do |article_number|
        if where(Artikelnummer: article_number)[0].attributes.to_a - where(Artikelnummer: article_number)[1].attributes.to_a == []
          article_numbers << article_number
        end
      end
      return article_numbers
    end


    def self.differences
      JobLogger.info("=" * 50)
      JobLogger.info("Started Job: webartikel:show_differences")

      non_unique.each do |article_number|
        JobLogger.info(article_number + ": " +
                       where(Artikelnummer: article_number)[0].different_attributes(where(Artikelnummer: article_number)[1]).to_s)
      end

      JobLogger.info("Finished Job: webartikel:show_differences")
      JobLogger.info("=" * 50)
    end


    def self.count_aktionen
      self.where{|w| ( w.PreisdatumVON <= Time.now) & (w.PreisdatumBIS >= Time.now)}.count
    end


    def self.update_categorizations
      Categorization.all.delete_all

      Webartikel.all.each do |webartikel|
        product = Product.find_by(number: webartikel.Artikelnummer) \
        or JobLogger.error("Product not found " + webartikel.Artikelnummer)

        if product
          webartikel.create_categorization(product: product)
          product.save \
          or JobLogger.error("Saving Product " + @product.number + " failed: " +  @product.errors.first.to_s)
        end
      end
    end


    # The Miranda way of categorizing...
    def self.categorize_from_properties
#      webartikel_numbers = MercatorMesonic::Eigenschaft.where(c003: 1, c002: 5).*.c000
#      Product.where(number: webartikel_numbers).count
#      well, should we double check??  ....

      @schnaeppchen_numbers = MercatorMesonic::Eigenschaft.where(c003: 1,
                                                                c002: 11).*.c000
      @schnaeppchen_category = ::Category.find_by(name_de: "Schnäppchen")

      Product.where(number: @schnaeppchen_numbers).each do |schnaeppchen|
        unless schnaeppchen.categorizations.where(category_id: @schnaeppchen_category.id).any?
          position = @schnaeppchen_category.categorizations.any? ? @schnaeppchen_category.categorizations.maximum(:position) + 1 : 1
          schnaeppchen.categorizations.create(category_id: @schnaeppchen_category.id,
                                              position: position)
        end
      end

      @topprodukte_numbers = MercatorMesonic::Eigenschaft.where(c003: 1,
                                                                c002: 12).*.c000
      @topprodukte_category = ::Category.topseller

      Product.where(number: @topprodukte_numbers).each do |topprodukte|
        unless topprodukte.categorizations.where(category_id: @topprodukte_category.id).any?
          position = @topprodukte_category.categorizations.any? ? @topprodukte_category.categorizations.maximum(:position) + 1 : 1
          topprodukte.categorizations.create(category_id: @topprodukte_category.id,
                                             position: position)
        end
      end

      @fireworks_numbers = MercatorMesonic::Eigenschaft.where(c003: 1,
                                                              c002: 35).*.c000
      @fireworks_category = ::Category.find_by(name_de: "Feuerwerk")

      Product.where(number: @fireworks_numbers).each do |firework|
        firework.update(not_shippable: true)
        unless firework.categorizations.where(category_id: @fireworks_category.id).any?
          position = @fireworks_category.categorizations.any? ? @fireworks_category.categorizations.maximum(:position) + 1 : 1
          firework.categorizations.create(category_id: @fireworks_category.id,
                                          position: position)
        end
      end
    end


    # --- Instance Methods --- #

    def readonly?  # prevents unintentional changes
      true
    end


    def import_and_return_product
      @product = create_product

      if Constant.find_by_key('erp_product_variations').try(:value) == "true"
        product_variations.each do |product_number|
          create_inventory(product: @product,
                           store: product_number.split("-")[1],
                           size: product_number.split("-")[2],
                           number: product_number)
          price = create_price(inventory: @inventory)
        end
      else
        @inventory = create_inventory(product: @product)
        @price = create_price(inventory: @inventory)
      end
      create_categorization(product: @product)
      create_recommendations(product: @product)

      return @product
    end


    def create_product
      @product = Product.find_by(number: self.Artikelnummer)

      if @product && @product.description_de.nil? # Let's fix missing descriptions here on the fly
        @product.update(description_de: comment.present? ? comment : self.Bezeichnung)
      end

      if @product && @product.lifecycle.available_transitions.*.name.include?(:reactivate)
        @product.lifecycle.reactivate!(User::JOBUSER)
      end

      @product ||= Product.new(number:         self.Artikelnummer,
                               title_de:       self.Bezeichnung,
                               description_de: comment.present? ? comment : self.Bezeichnung)
      @product.save or JobLogger.error("Product " + @product.number + " could not be created:" + @product.errors.messages.to_s)

      if Rails.application.config.try(:icecat) == true
        @product.update_from_icecat(from_today: false)
      end

      return @product
    end


    def create_inventory(product: nil, store: nil, size: nil, number: nil)
      delivery_time =  self.Zusatzfeld5 or I18n.t("mercator.on_request")

      @inventory = Inventory.new(product_id:              product.id,
                                 number:                  number.present? ? number : self.Artikelnummer,
                                 name_de:                 self.Bezeichnung,
                                 comment_de:              comment,
                                 weight:                  self.Gewicht,
                                 charge:                  self.LfdChargennr,
                                 unit:                    "Stk.",
                                 delivery_time:           delivery_time,
                                 amount:                  0,
                                 erp_updated_at:          letzteAend,
                                 erp_vatline:             self.Steuersatzzeile,
                                 erp_article_group:       self.ArtGruppe,
                                 erp_provision_code:      self.Provisionscode,
                                 erp_characteristic_flag: self.Auspraegungsflag,
                                 infinite:                true,
                                 just_imported:           true,
                                 alternative_number:      self.AltArtNr1,
                                 storage:                 store,
                                 size:                    size)
      @inventory.save \
      or JobLogger.error("Saving Inventory failed: " + @inventory.errors.first.to_s)

      return @inventory
    end


    def create_price(inventory: nil)
      @price = ::Price.new(scale_from: self.AbMenge,
                           scale_to: 9999,
                           vat: self.Steuersatzzeile * 10,
                           inventory_id: inventory.id,
                           erp_identifier: self.mesokey)

      if Constant.find_by_key('import_gross_prices_from_erp').try(:value) == "true"
        @price.value = self.Preis * 10 / ( 10 + self.Steuersatzzeile ) # convert to net price
      else
        @price.value = self.Preis
      end

      if self.PreisdatumVON && self.PreisdatumVON <= Time.now &&
         self.PreisdatumBIS && self.PreisdatumBIS >= Time.now
        @price.attributes = { promotion: true,
                              valid_from: self.PreisdatumVON,
                              valid_to: self.PreisdatumBIS}
      else
        @price.attributes = { valid_from: Date.today, valid_to: Date.new(9999,12,31) }
      end

      @price.save \
      or JobLogger.error("Saving Price failed: " +  @price.errors.first.to_s)

      return @price
    end


    def create_recommendations(product: nil)
      product.recommendations.destroy_all

      if self.Notiz1.present? &&
         self.Notiz2.present? &&
         @recommended_product = Product.find_by(number: self.Notiz1)
        product.recommendations.new(recommended_product: @recommended_product,
                                    reason_de: self.Notiz2)
      end

      return product.recommendations
    end


    def comment
      if self.Langtext1.present?
        return self.Langtext1.to_s + " " + self.Langtext2.to_s
      else
        return self.Langtext2.to_s
      end
    end


    def create_categorization(product: nil)
      if category = ::Category.find_by(erp_identifier: self.Artikeluntergruppe)
        Categorization.complement(product: product, category: category)
      end

      # Squeel categories
      ::Category.where.not(squeel_condition: [nil, '']).each do |category|
        begin
          if MercatorMesonic::Webartikel.where{instance_eval(category.squeel_condition)}.include?(self)
            Categorization.complement(product: product, category: category)
          end
        rescue
          JobLogger.fatal("Invalid Squeel Condition for Category " + category.id.to_s + " " + category.name_de + " : " + category.squeel_condition)
        end
      end

      unless product.categories.any?
        Categorization.complement(product: product, category: ::Category.auto)
      end
    end


    def product_variations
      # there is no default scope on Artikelstamm
      MercatorMesonic::Artikelstamm.where(c011: self.Artikelnummer,
                                          c014: 2)
                                   .mesocomp.mesoyear.*.c002
    end
  end
end