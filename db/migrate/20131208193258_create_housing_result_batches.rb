class CreateHousingResultBatches < ActiveRecord::Migration
  def change
    create_table :housing_result_batches do |t|

      t.timestamps
    end
  end
end
