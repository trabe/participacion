namespace :db do
  desc "Resets the database and loads it from db/dev_seeds.rb"
  task dev_seed: :environment do
    load(Rails.root.join("db", "dev_seeds.rb"))
  end

  desc "Resets geozones to the UDC ones from db/udc_geozone_seeds.rb"
  task udc_geozones_seed: :environment do
    load(Rails.root.join("db", "udc_geozone_seeds.rb"))
  end
end
