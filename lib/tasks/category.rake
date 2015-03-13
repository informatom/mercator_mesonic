namespace :mesonic do
  namespace :categories do
    # starten als: bundle exec rake mesonic:categories:create_missing RAILS_ENV=production
    desc 'Creates minimal mercator categories for products in webarticle view'
    task :create_missing => :environment do
      ::JobLogger.info("=" * 50)
      ::JobLogger.info("Started Job: mesonic:users:create_missing")

      jobuser = User.find_by(surname: "Job User")

      MercatorMesonic::Webartikel.all.each do |webartikel|
        mesonic_artikeluntergruppe = webartikel.Artikeluntergruppe
        if Category.find_by(erp_identifier: mesonic_artikeluntergruppe)
          puts "Category exists"
        else
          mesonic_category = MercatorMesonic::Category.find_by(c000: mesonic_artikeluntergruppe)
          category = Category.create( name_de: mesonic_category.c001,
                                      name_en: mesonic_category.c001,
                                      position: 1,
                                      erp_identifier: mesonic_artikeluntergruppe,
                                      description_de: mesonic_category.comment,
                                      long_description_de: mesonic_category.comment,
                                      filtermin: 1,
                                      filtermax: 100,
                                      usage: :standard)
          puts category.errors.first if category.errors
          category.lifecycle.activate!(jobuser) or category.errors.first
        end
      end

      # create parentrelation where possible
      Category.where.not(erp_identifier: nil).where(ancestry: nil).each do |category|
        puts ","
        mesonic_category =  MercatorMesonic::Category.find_by(c000: category.erp_identifier)
        if  mesonic_category.parent_key && parent = Category.find_by(erp_identifier: mesonic_category.parent_key)
          category.update(parent: parent) or category.errors.first
        end
      end

      ::JobLogger.info("Finished Job: mesonic:users:create_missing")
      ::JobLogger.info("=" * 50)
    end
  end
end
