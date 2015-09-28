# encoding: utf-8

namespace :webartikel do

  # starten als: bundle exec rake webartikel:import RAILS_ENV=production
  desc 'Import from Mesonic Webartikel view into inventories'
  task :import => :environment do
    MercatorMesonic::Webartikel.test_connection \
    and MercatorMesonic::Webartikel.import(update: "all")
  end

# starten als: bundle exec rake webartikel:miranda_import RAILS_ENV=production
  desc 'Miranda-specific Import from Mesonic Webartikel view into inventories'
  task :miranda_import => :environment do
    Product.delete_all
    Price.delete_all
    Inventory.delete_all
    Productrelation.delete_all
    Categorization.delete_all
    MercatorMesonic::Webartikel.test_connection
    MercatorMesonic::Webartikel.import(update: "all")
    MercatorMesonic::Webartikel.categorize_from_properties
    MercatorMesonic::Bild.import(missing: true)
    MercatorMesonic::Ersatzartikel.import_relations
    Product.all.each do |product|
      if product.lifecycle.available_transitions.*.name.include?(:activate)
        product.lifecycle.activate!(User::JOBUSER)
      end
      if product.lifecycle.available_transitions.*.name.include?(:reactivate)
        product.lifecycle.reactivate!(User::JOBUSER)
      end
    end
  end


  # starten als: bundle exec rake webartikel:update RAILS_ENV=production
  desc 'Update from Mesonic Webartikel view into inventories'
  task :update => :environment do
    begin
      MercatorMesonic::Webartikel.test_connection \
      and MercatorMesonic::Webartikel.import(update: "changed")
      Product.check_price(fix: true)
    rescue
      UserMailer.job_failed("Mesonic Webartikel Update").deliver
    end
  end


  # starten als: bundle exec rake webartikel:update_prices RAILS_ENV=production
  desc 'Update from Mesonic Webartikel view into inventories'
  task :update_prices => :environment do
    begin
      MercatorMesonic::Webartikel.test_connection \
      and Product.check_price(fix: true)
      Product.deprecate
    rescue
      UserMailer.job_failed("Update Prices").deliver
    end
  end


  # starten als: bundle exec rake webartikel:miranda_update RAILS_ENV=production
  desc 'Miranda-specific Update from Mesonic Webartikel view into inventories'
  task :miranda_update => :environment do
    MercatorMesonic::Webartikel.test_connection \
    and MercatorMesonic::Webartikel.import(update: "changed")
    MercatorMesonic::Webartikel.categorize_from_properties
    MercatorMesonic::Bild.import(missing: true)
    MercatorMesonic::Ersatzartikel.import_relations
  end


  # starten als: bundle exec rake webartikel:remove_orphans RAILS_ENV=production
  desc 'Remove ophaned inventories'
  task :remove_orphans => :environment do
    MercatorMesonic::Webartikel.test_connection \
    and MercatorMesonic::Webartikel.remove_orphans
  end

  # starten als: bundle exec rake webartikel:show_differences RAILS_ENV=production
  desc 'Show differences in instances with same article number'
  task :show_differences => :environment do
    MercatorMesonic::Webartikel.test_connection \
    and MercatorMesonic::Webartikel.differences
  end

  # starten als: bundle exec rake webartikel:test_connection RAILS_ENV=production
  desc 'Testing the database connection'
  task :test_connection => :environment do
    MercatorMesonic::Webartikel.test_connection
  end
end