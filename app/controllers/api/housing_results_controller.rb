class Api::HousingResultsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:create, :error, :most_recent]

  respond_to :json

  def create
    batch = HousingResultBatch.new
    batch.save

    params["results"].each do |result|
      # skip if we've already seen this one
      unless HousingResult.where({ :day => result["day"], :title => result["title"], :price  => result["price"] }).any?

        unless HousingResult.in_blacklisted_location?(result["location"]) || HousingResult.in_blacklisted_title?(result["title"])
          hr = HousingResult.new do |hr|
            puts hr.inspect
            puts hr.class.to_s
            hr.day              = result["day"]
            hr.title            = result["title"]
            hr.target           = result["target"]
            hr.location         = result["location"]
            hr.price            = result["price"]
            hr.bedrooms         = result["bedrooms"]
            hr.sq_ft            = result["sq_ft"]
            hr.pet_context      = result["pet_context"]
            hr.map_lat          = result["map_lat"]
            hr.map_lng          = result["map_lng"]
            hr.image_list       = result["image_list"]
            hr.looks_like_scam  = result["looks_like_scam"]
            hr.housing_result_batch = batch
          end
          hr.save!
        end
      end
    end

    HousingResultsMailer.notification_email(batch).deliver! if batch.housing_results.any?

    render :nothing => true
  rescue Exception => ex
    puts ex.inspect
    StatusMailer.status_email(ex.inspect).deliver!
    render :nothing => true
  end

  def error
    StatusMailer.status_email(request.raw_post).deliver!

    render :nothing => true
  end

  def most_recent
    most_recent = HousingResult.last

    render :json => {
      :day    => most_recent.try(:day),
      :title  => most_recent.try(:title),
      :price  => most_recent.try(:price),
      :target => most_recent.try(:target)
    }.to_json
  end

end
