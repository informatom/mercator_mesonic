# encoding: utf-8

namespace :price do

  # starten als: bundle exec rake price:convert_gross_to_net_prices RAILS_ENV=production
  desc 'Converts gross prices to net prices DANGEROUS!'
  task :convert_gross_to_net_prices => :environment do
    Price.all.each do |price|
      price.update(value: price.value * 100 / (100 + price.vat))
    end
  end
end