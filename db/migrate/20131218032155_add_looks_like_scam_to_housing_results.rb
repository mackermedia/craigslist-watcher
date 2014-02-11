class AddLooksLikeScamToHousingResults < ActiveRecord::Migration
  def change
    add_column :housing_results, :looks_like_scam, :boolean
  end
end
