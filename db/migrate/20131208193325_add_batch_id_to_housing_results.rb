class HousingResult < ActiveRecord::Base
end

class AddBatchIdToHousingResults < ActiveRecord::Migration

  def change
    add_column :housing_results, :housing_result_batch_id, :integer

    hrb = HousingResultBatch.first_or_initialize
    hrb.save!

    HousingResult.all.each do |hr|
      hr.update_attribute(:housing_result_batch_id, hrb.id)
    end
  end
end
