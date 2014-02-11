class RemoveUserContentFromHousingResults < ActiveRecord::Migration
  def change
    remove_column :housing_results, :user_content
  end
end
