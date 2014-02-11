class AddUserContentToHousingResult < ActiveRecord::Migration
  def change
    add_column :housing_results, :user_content, :text
  end
end
