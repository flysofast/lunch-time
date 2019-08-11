require 'net/http'
require 'json'
require 'date'
require 'open-uri'
class MainpageController < ApplicationController
  def index
    @day_shift = params[:day_shift].to_i || 0
    # @language = params[:language] || 'fi'
    @date = DateTime.now + @day_shift
    
    @sodexo_data = get_hertsi_menu
    @reaktori_data = get_reaktori_menu
    # @json = res.body
    rescue => e
      puts "failed #{e}"
  end

  def get_hertsi_menu
    date_string = @date.strftime("%Y/%m/%d")
    uri_string = "https://www.sodexo.fi/ruokalistat/output/daily_json/12812/#{date_string}/fi"
    return get_json_data(uri_string)["courses"]
  end

  def get_reaktori_menu
    date_string = @date.strftime("%Y-%-m-%-d")
    uri_string_en = "https://www.fazerfoodco.fi/api/restaurant/menu/day?date=#{date_string}&language=en&restaurantPageId=180077"
    uri_string_fi = "https://www.fazerfoodco.fi/api/restaurant/menu/day?date=#{date_string}&language=fi&restaurantPageId=180077"
    data_en = get_json_data(uri_string_en)
    data_fi = get_json_data(uri_string_fi)
    
    menu = []
    data_fi["LunchMenu"]["SetMenus"].each_with_index do |category, ci|
      category["Meals"].each_with_index do |meal, ii|
        item = {}
        item["category"] = category["Name"]
        item["category_en"] =  data_en["LunchMenu"]["SetMenus"][ci]["Name"]
        item["price"] = category["Price"]
        item["title_fi"] = meal["Name"]
        item["title_en"] = data_en["LunchMenu"]["SetMenus"][ci]["Meals"][ii]["Name"]
        item["properties"] = meal["Diets"].join(", ")
        menu.push(item)
      end
    end
    return menu
  end

  def get_json_data (uri_string)
    # uri = URI(uri_string)
    # http = Net::HTTP.new(uri.host, uri.port)
    # http.use_ssl = true
    # req = Net::HTTP::Get.new(uri.path, 'Content-Type' => 'text/json')
    # res = http.request(req)
    res = Net::HTTP.get_response(URI.parse(uri_string))
    return JSON.parse(res.body)
  end
end
