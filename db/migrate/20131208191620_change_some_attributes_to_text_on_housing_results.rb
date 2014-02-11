class ChangeSomeAttributesToTextOnHousingResults < ActiveRecord::Migration
  def change
    change_column :housing_results, :title, :text, :null => false
    change_column :housing_results, :target, :text, :null => false
    change_column :housing_results, :location, :text, :null => false
    change_column :housing_results, :pet_context, :text, :null => false
  end
end
