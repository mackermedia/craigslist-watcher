class CreateHousingResults < ActiveRecord::Migration
  def change
    create_table :housing_results do |t|
      t.string :day, :null => false
      t.string :title, :null => false
      t.string :target, :null => false
      t.string :price
      t.string :bedrooms
      t.string :sq_ft
      t.string :location
      t.string :pet_context
      t.string :map_lat
      t.string :map_lng

      t.timestamps
    end
  end
end
