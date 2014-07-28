# encoding: utf-8

namespace :webartikel do

  # starten als: 'bundle exec rake webartikel:import'
  # in Produktivumgebungen: 'bundle exec rake webartikel:import RAILS_ENV=production'
  desc 'Import from Mesonic Webartikel view into inventories'
  task :import => :environment do
    ::JobLogger.info("=" * 50)
    ::JobLogger.info("Started Job: webartikel:import")

    if MercatorMesonic::Webartikel.test_connection
      MercatorMesonic::Webartikel.import(update: "all")
    end

    ::JobLogger.info("Finished Job: webartikel:import")
    ::JobLogger.info("=" * 50)
  end

  # starten als: 'bundle exec rake webartikel:update'
  # in Produktivumgebungen: 'bundle exec rake webartikel:update RAILS_ENV=production'
  desc 'Update from Mesonic Webartikel view into inventories'
  task :update => :environment do
    ::JobLogger.info("=" * 50)
    ::JobLogger.info("Started Job: webartikel:update")

    if MercatorMesonic::Webartikel.test_connection
      MercatorMesonic::Webartikel.import(update: "changed")
    end

    ::JobLogger.info("Finished Job: webartikel:update")
    ::JobLogger.info("=" * 50)
  end

    # starten als: 'bundle exec rake webartikel:remove_orphans'
  # in Produktivumgebungen: 'bundle exec rake webartikel:remove_orphans RAILS_ENV=production'
  desc 'Remove ophaned inventories'
  task :remove_orphans => :environment do
    ::JobLogger.info("=" * 50)
    ::JobLogger.info("Started Job: webartikel:remove_orphans")

    if MercatorMesonic::Webartikel.test_connection
      MercatorMesonic::Webartikel.remove_orphans
    end

    ::JobLogger.info("Finished Job: webartikel:remove_orphans")
    ::JobLogger.info("=" * 50)
  end
end