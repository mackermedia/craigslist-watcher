class CreateHousingResults < ActiveRecord::Migration
  def change
    create_table :housing_results do |t|

      t.timestamps
    end
  end
end
