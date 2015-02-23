# encoding: utf-8

namespace :webartikel do

  # starten als: bundle exec rake webartikel:import RAILS_ENV=production
  desc 'Import from Mesonic Webartikel view into inventories'
  task :import => :environment do
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.import(update: "all")
  end

  # starten als: bundle exec rake webartikel:update RAILS_ENV=production
  desc 'Update from Mesonic Webartikel view into inventories'
  task :update => :environment do
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.import(update: "changed")
  end

  # starten als: bundle exec rake webartikel:remove_orphans RAILS_ENV=production
  desc 'Remove ophaned inventories'
  task :remove_orphans => :environment do
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.remove_orphans
  end

  # starten als: bundle exec rake webartikel:show_differences RAILS_ENV=production
  desc 'Show differences in instances with same article number'
  task :show_differences => :environment do
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.differences
  end

  # starten als: bundle exec rake webartikel:test_connection RAILS_ENV=production
  desc 'Testing the database connection'
  task :test_connection => :environment do
    MercatorMesonic::Webartikel.test_connection
  end
end