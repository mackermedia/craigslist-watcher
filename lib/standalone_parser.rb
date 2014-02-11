require 'open-uri'
require 'nokogiri'
require 'httparty'
require 'json'
require 'pry'

# SERVER_ADDRESS = "http://localhost:3002"
# SERVER_ADDRESS = "http://your-dns.herokuapp.com"

SCAM_BLACKLIST = [
  /\w+\b\W@\Wyahoo.com/
]

DESCRIPTION_BLACKLIST = [
  /solana/i,
  /roosevelt park apartments/i,
  /university village at boulder creek/i,
  /brookside/i,
  /amli at flatirons/i,
  /steel yards/i,
  /www.habitatapts.com/i,
  /coronado apartments/i,
  /www.thebouldercreekapartments.com/i,
  /tantra lake/i,
  /lafayette, co/i,
  /twoninenorth/i,
  /the cattail/i,
  /www.plazaonbroadway.com/i,
  /vistoso condo/i,
  /spanish towers/i,
  /the boulders/i,
  /peakview apartment/i,
  /peakviewapts.com/i,
  /bluffs at castle rock/i,
  /www.uptownbroadwayapts.com/i,
  /liveatcanterwood.com/i,
  /uptown broadway/i,
  /gold run/i,
  /the hub/i,
  /redstone ranch/i,
  /gregory creek/i,
  /glenlake apartments/i,
  /starpropmgmt/i,
  /ezhomerents.com/i,
  /two nine north apartment/i,
  /realrentalpros.com/i,
  /great location great community feel/i,
  /sterling university peaks/i,
  /need help renting your house or condo/i,
  /fixmycredit/i,
  /villa del prado/i,
  /pre-leasing/i,
  /buffalocanyon.com/i,
  /303-494-5462/,
  /do not miss these beautifully renovated apartment homes/i,
  /i am in the office now/i,
  /cavalierapts.com/i,
  /meadow creek apartments/i,
  /will pick up anything metal/i
]

HousingResult = Struct.new(
  :day,
  :title,
  :target,
  :price,
  :bedrooms,
  :sq_ft,
  :location,
  :pet_context,
  :map_lat,
  :map_lng,
  :flagged_for_removal,
  :image_list,
  :looks_like_scam
)

class CraigslistParser

  def self.run
    fetch_most_recent

    @result_collection = []

    parse_batch(0)
    parse_batch(1) if @result_collection.size == 100

    # reverse the order of results so that the last one is really the most recent instead of first
    @result_collection.reverse!

    if @result_collection.size > 50
      @result_collection.each_slice(50) do |slice|
        post_results(slice)
      end
    else
      post_results(@result_collection)
    end
  end

  private

  def self.craigslist_base_url
    "http://boulder.craigslist.org"
  end

  def self.craigslist_search_url(page)
    "http://boulder.craigslist.org/search/apa?query=&zoomToPosting=&minAsk=&maxAsk=2000&bedrooms=&housing_type=&s=#{page * 100}&maxAsk=100"
  end

  def self.craigslist_search_html(page_num)
    @page = Nokogiri::HTML(open(craigslist_search_url(page_num)))
  end

  def self.result_rows(page_num)
    craigslist_search_html(page_num).css("//div[@class='content']/p[@class='row']")
  end

  def self.parse_batch(page_num = 0)
    self.result_rows(page_num).each do |row|
      @row    = row
      @day    = row.css(".date").text
      @link   = row.css("a")[1]
      @title  = @link.inner_text
      @target = "#{craigslist_base_url}#{@link["href"]}"

      @extra_text = @row.search(".l2").inner_text
      @price      = @extra_text.scan(/(\$\d+)/).join('')

      # stop if we've seen this one before
      break if @target == @most_recent_target || (
        @day    == @most_recent_day &&
        @title  == @most_recent_title &&
        @price  == @most_recent_price
        )

      result = create_result_from_row
      next unless result

      result_as_hash = Hash[result.each_pair.to_a]
      @result_collection << result_as_hash
    end
  end

  def self.lookup_attrs(day, title)
    { :day => day, :title => title }
  end

  def self.create_result_from_row
    @location = @extra_text.scan(/\((.*)\)/).join('')
    @bedrooms = @extra_text.scan(/(\d+br)/).join('')
    @sq_ft = @extra_text.scan(/(\d+ft)/).join('')

    fetch_result_page_user_content

    return if in_description_blacklist?

    @pet_context = parsed_pet_context

    @flagged_for_removal = flagged_for_removal?

    if has_map? && !parsed_map_element.nil? && !@flagged_for_removal
      @map_lat = parsed_map_element['data-latitude']
      @map_lng = parsed_map_element['data-longitude']
    end

    @image_list   = image_list

    @looks_like_scam = in_scam_blacklist?

    HousingResult.new(
      @day,
      @title,
      @target,
      @price,
      @bedrooms,
      @sq_ft,
      @location,
      @pet_context,
      @map_lat,
      @map_lng,
      @flagged_for_removal,
      @image_list,
      @looks_like_scam
    )
  rescue Exception => ex
    post_error(ex.inspect.to_json)
    raise
  end

  def self.result_page
    @result_page = Nokogiri::HTML(open(@target))
  end

  def self.fetch_result_page_user_content
    @result_page_user_content = result_page.css(".userbody").text
  end

  def self.parsed_pet_context
    pet_matches = @result_page_user_content.scan(/(?:\w+\W+){4}(?=pet)(?:\w+\W+){4}/) || []
    dog_matches = @result_page_user_content.scan(/(?:\w+\W+){4}(?=dog)(?:\w+\W+){4}/) || []
    pet_contexts = [pet_matches + dog_matches].flatten.uniq.join(",").gsub("\n", "<br>")
  end

  def self.has_map?
    @row.css(".px").inner_html.include? "map"
  end

  def self.parsed_map_element
    @parsed_map_element = result_page.css("#map").first
  end

  def self.flagged_for_removal?
    result_page.text.include?("flagged for removal")
  end

  def self.image_list
    image_list = @result_page_user_content.scan(/imgList = \[(.+)\]/) || []
    image_list = image_list.flatten
    image_list = image_list.first.gsub("\"", '') if image_list.any?
  end

  def self.in_scam_blacklist?
    SCAM_BLACKLIST.any? { |regex| @result_page_user_content.scan(regex).any? }
  end

  def self.in_description_blacklist?
    DESCRIPTION_BLACKLIST.any? { |regex| @result_page_user_content.scan(regex).any? }
  end

  def self.post_results(results)
    request = HTTParty.post("#{SERVER_ADDRESS}#{api_endpoint}/create",
      :body    => { :results => results }.to_json,
      :headers => { 'Content-Type' => 'application/json' })
    puts request.inspect
  rescue Exception => ex
    post_error(ex.inspect.to_json)
    raise
  end

  def self.api_endpoint
    "/craigslist_watcher/api/housing_results"
  end

  def self.post_error(message_json)
    request = HTTParty.post("#{SERVER_ADDRESS}#{api_endpoint}/error", body: message_json)
    puts request.inspect
  end

  def self.fetch_most_recent
    request = HTTParty.get("#{SERVER_ADDRESS}#{api_endpoint}/most_recent")

    converted = JSON.parse(request.body)

    @most_recent_day    = converted['day']
    @most_recent_title  = converted['title']
    @most_recent_price  = converted['price']
    @most_recent_target = converted['target']
  rescue Exception => ex
    post_error(ex.inspect.to_json)
    raise
  end

end

CraigslistParser.run
