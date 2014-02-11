namespace :housing_results do

  desc 'Clear all existing records'
  task :clear => :environment do
    HousingResult.destroy_all
  end
end
