class HousingResultBatchController < ApplicationController
  def show
    @batch = HousingResultBatch.find_by_id(params[:id])
  end
end
