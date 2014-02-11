class AddFlaggedForRemovalToHousingResults < ActiveRecord::Migration
  def change
    add_column :housing_results, :flagged_for_removal, :boolean
  end
end
