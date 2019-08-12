require 'net/http'
require 'json'
require 'date'
require 'open-uri'
class MainpageController < ApplicationController
  def index
    @day_shift = params[:day_shift].to_i || 0
    # @language = params[:language] || 'fi'
    @date = DateTime.now + @day_shift
    
    @all_menus = []
    @all_menus.push(get_reaktori_menu)
    @all_menus.push(get_hertsi_menu)
    @all_menus.push(get_saas_menu)

    # @json = res.body
    rescue => e
      puts "failed #{e}"
  end

  def get_hertsi_menu
    date_string = @date.strftime("%Y/%m/%d")
    uri_string = "https://www.sodexo.fi/ruokalistat/output/daily_json/12812/#{date_string}/fi"
    menu = get_json_data(uri_string)["courses"]
    c_menu = menu.group_by{|h| [h.delete("category"), h.delete("price")]}
    menu = []
    c_menu.each do |(category, price), meals|
      c = {"category_fi" => category, "price" => price, "meals" => meals}
      menu.push(c)
    end

    return {:name => "Hertsi", :menu => menu}
  end

  def get_reaktori_menu
    date_string = @date.strftime("%Y-%-m-%-d")
    uri_string_en = "https://www.fazerfoodco.fi/api/restaurant/menu/day?date=#{date_string}&language=en&restaurantPageId=180077"
    uri_string_fi = "https://www.fazerfoodco.fi/api/restaurant/menu/day?date=#{date_string}&language=fi&restaurantPageId=180077"
    data_en = get_json_data(uri_string_en)
    data_fi = get_json_data(uri_string_fi)
    
    menu = []
    data_fi["LunchMenu"]["SetMenus"].each_with_index do |category, ci|
      c_hash = {}
      c_hash["category_en"] = data_en["LunchMenu"]["SetMenus"][ci]["Name"]
      c_hash["category_fi"] = category["Name"]
      c_hash["price"] = category["Price"]
      c_hash["meals"] = []

      category["Meals"].each_with_index do |meal, ii|
        item = {}
        item["title_fi"] = meal["Name"]
        item["title_en"] = data_en["LunchMenu"]["SetMenus"][ci]["Meals"][ii]["Name"]
        item["properties"] = meal["Diets"].join(", ")
        c_hash["meals"].push(item)
      end
      menu.push(c_hash)

    end
    return  {:name => "Reaktori", :menu => menu}
  end

  def get_saas_menu
    week_num = @date.strftime("%V")
    dow_num = @date.wday == 0 ?  7 : @date.wday
    
    uri_string_en = "https://www.juvenes.fi/DesktopModules/Talents.LunchMenu/LunchMenuServices.asmx/GetMenuByWeekday?KitchenId=60038&MenuTypeId=3&Week=#{week_num}&Weekday=#{dow_num}&lang=%27en%27&format=json"
    uri_string_fi = "https://www.juvenes.fi/DesktopModules/Talents.LunchMenu/LunchMenuServices.asmx/GetMenuByWeekday?KitchenId=60038&MenuTypeId=3&Week=#{week_num}&Weekday=#{dow_num}&lang=%27fi%27&format=json"
    data_en = JSON.parse(get_json_data(uri_string_en)["d"])
    data_fi = JSON.parse(get_json_data(uri_string_fi)["d"])
    byebug
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
