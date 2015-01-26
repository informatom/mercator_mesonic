# encoding: utf-8

namespace :webartikel do

  # starten als: 'bundle exec rake webartikel:import RAILS_ENV=production'
  desc 'Import from Mesonic Webartikel view into inventories'
  task :import => :environment do
    ::JobLogger.info("=" * 50)
    ::JobLogger.info("Started Job: webartikel:import")
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.import(update: "all")
    ::JobLogger.info("Finished Job: webartikel:import")
    ::JobLogger.info("=" * 50)
  end

  # starten als: 'bundle exec rake webartikel:update RAILS_ENV=production'
  desc 'Update from Mesonic Webartikel view into inventories'
  task :update => :environment do
    ::JobLogger.info("=" * 50)
    ::JobLogger.info("Started Job: webartikel:update")
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.import(update: "changed")
    ::JobLogger.info("Finished Job: webartikel:update")
    ::JobLogger.info("=" * 50)
  end

  # starten als: 'bundle exec rake webartikel:remove_orphans RAILS_ENV=production'
  desc 'Remove ophaned inventories'
  task :remove_orphans => :environment do
    ::JobLogger.info("=" * 50)
    ::JobLogger.info("Started Job: webartikel:remove_orphans")
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.remove_orphans
    ::JobLogger.info("Finished Job: webartikel:remove_orphans")
    ::JobLogger.info("=" * 50)
  end

  # starten als: 'bundle exec rake webartikel:show_differences RAILS_ENV=production'
  desc 'Show differences in instances with same article number'
  task :show_differences => :environment do
    ::JobLogger.info("=" * 50)
    ::JobLogger.info("Started Job: webartikel:show_differences")
    MercatorMesonic::Webartikel.test_connection and
      MercatorMesonic::Webartikel.differences
    ::JobLogger.info("Finished Job: webartikel:show_differences")
    ::JobLogger.info("=" * 50)
  end

  # starten als: 'bundle exec rake webartikel:test_connection RAILS_ENV=production'
  desc 'Testing the database connection'
  task :test_connection => :environment do
    MercatorMesonic::Webartikel.test_connection
  end
end