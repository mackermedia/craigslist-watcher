class HousingResult < ActiveRecord::Base

  belongs_to :housing_result_batch

  validates :day, :title, :target, :presence => true

  def self.in_blacklisted_location?(location)
    location ||= ""
    LOCATION_BLACKLIST.any? { |word| location.downcase.include?(word) }
  end

  def self.in_blacklisted_title?(title)
    title ||= ""
    TITLE_BLACKLIST.any? { |word| title.downcase.include?(word) }
  end

  def to_html
    "<tr><td>#{day}</td><td>#{location}</td><td><a href='#{target}'>#{title}</a></td><td>#{price}</td><td>#{bedrooms}</td><td>#{sq_ft}</td><td>#{pet_context}</td><td>#{map_html}</td><td>#{images_html}</td><td>#{flagged_for_removal_html}</td><td>#{scam_blacklist_html}</td></tr>"
  end

  private

  def map_html
    if map_lat && map_lng
      "<img src='http://maps.google.com/maps/api/staticmap?center=Downtown%20Boulder%20CO&size=300x250&sensor=false&markers=#{map_lat},#{map_lng}'>"
    else
      "N/A"
    end
  end

  def images_html
    if image_list?
      html = "<div class='image-list'>"
      image_list.split(',').each do |img|
        html << "<img width='250' src='#{img}' />"
      end
      html << "</div>"
    end
  end

  def flagged_for_removal_html
    "<strong class='removed'>X</strong>" if flagged_for_removal?
  end

  def scam_blacklist_html
    "<strong class='removed'>X</strong>" if looks_like_scam?
  end
end
