class AddImageListToHousingResults < ActiveRecord::Migration
  def change
    add_column :housing_results, :image_list, :text
  end
end
