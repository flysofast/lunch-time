require 'net/http'
require 'json'
require 'date'
class MainpageController < ApplicationController
  def index
    update_view_count
    @day_shift = params[:day_shift].to_i || 0
    # @language = params[:language] || 'fi'
    @date = DateTime.now + @day_shift
    @all_menus = []
    @all_menus.push(get_reaktori_menu)
    @all_menus.push(get_hertsi_menu)
    @all_menus.push(get_juvenes_menu(60038, [77, 3]))
    @all_menus.push(get_juvenes_menu(6, [60, 86]))
    # @json = res.body
    
  end

  def get_hertsi_menu
    date_string = @date.strftime("%Y/%m/%d")
    uri_string = "https://www.sodexo.fi/ruokalistat/output/daily_json/12812/#{date_string}/fi"
    menu = get_json_data(uri_string)["courses"]
    c_menu = menu.group_by{|h| [h.delete("category"), h.delete("price")]}
    menu = []
    c_menu.each do |(category, price), items|
      c = {"category_fi" => category, "price" => price, "items" => items}
      menu.push(c)
    end
    return {:name => "Hertsi", :menu => menu}
    rescue => e
      logger.debug ActiveSupport::LogSubscriber.new.send(:color, e.message, :red )
      return {:name => "Hertsi", :menu => []}
  end

  def get_reaktori_menu
    date_string = @date.strftime("%Y-%-m-%-d")
    uri_string_en = "https://www.fazerfoodco.fi/api/restaurant/menu/day?date=#{date_string}&language=en&restaurantPageId=180077"
    uri_string_fi = "https://www.fazerfoodco.fi/api/restaurant/menu/day?date=#{date_string}&language=fi&restaurantPageId=180077"
    data_en = get_json_data(uri_string_en)
    data_fi = get_json_data(uri_string_fi)
    
    menu = []
    data_fi["LunchMenu"]["SetMenus"].each_with_index do |category, ci|
      if category["Meals"].length == 0
        next
      end
      c_hash = {}
      c_hash["category_en"] = data_en["LunchMenu"]["SetMenus"][ci]["Name"]
      c_hash["category_fi"] = category["Name"]
      c_hash["price"] = category["Price"]
      c_hash["items"] = []

      category["Meals"].each_with_index do |meal, ii|
        item = {}
        item["title_fi"] = meal["Name"]
        item["title_en"] = data_en["LunchMenu"]["SetMenus"][ci]["Meals"][ii]["Name"]
        item["properties"] = meal["Diets"].join(", ")
        c_hash["items"].push(item)
      end
      menu.push(c_hash)
    end
    return  {:name => "Reaktori", :menu => menu}

    rescue => e
      logger.debug ActiveSupport::LogSubscriber.new.send(:color, e.message, :red )
      return {:name => "Reaktori", :menu => []}
  end

  def get_juvenes_menu (kitchenId, menu_type_ids)
    kitchenName = "Juvenes restaurant"
    begin
      week_num = @date.strftime("%V")
      dow_num = @date.wday == 0 ?  7 : @date.wday

      menu_types_data = []
      menu_type_ids.each do |id|
        uri = "https://www.juvenes.fi/DesktopModules/Talents.LunchMenu/LunchMenuServices.asmx/GetMenuByWeekday?KitchenId=#{kitchenId}&MenuTypeId=#{id}&Week=#{week_num}&Weekday=#{dow_num}&lang=%27en%27&format=json"
        menu_data = JSON.parse(get_json_data(uri)["d"])
        menu_types_data.push(menu_data)
      end

      menu = []
      menu_types_data.each_with_index do |data, index|
        if data["KitchenName"] != "[CLOSED]"
          kitchenName = data["KitchenName"]
          menu.push({"category_fi" => "<br/> <strong>#{data["MenuTypeName"]}'s menu</strong> <br/>", "items" => []})
          begin
            data["MealOptions"].each do |category|
              if category["Name_FI"].empty?
                next
              end
              c_hash = {}
              c_hash["category_en"] = category["Name_EN"]
              c_hash["category_fi"] = category["Name_FI"]
              c_hash["price"] = (index == 0 || category["Name_FI"] == "PANINIATERIA") ? "2,60/ 5,60/ 7,80€" : "4,95/ 8,50/ 9,40€"
              c_hash["items"] = []
              category["MenuItems"].each_with_index do |menu_item|
                if menu_item["Name_FI"].empty?
                  next
                end
                item = {}
                item["title_fi"] = menu_item["Name_FI"]
                item["title_en"] = menu_item["Name_EN"]
                item["ingredients"] = menu_item["Ingredients"]
                item["properties"] = menu_item["Diets"]
                c_hash["items"].push(item)
              end
              menu.push(c_hash)
          end
          rescue => e
            logger.debug ActiveSupport::LogSubscriber.new.send(:color, e.message, :red )
          end
        end
      end
      return {:name => kitchenName, :menu => menu}

    rescue => e
      logger.debug ActiveSupport::LogSubscriber.new.send(:color, e.message, :red )
      return {:name => kitchenName , :menu => []}
    end
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

  def update_view_count
    read_view_count
    today = {'count' => @viewCount['today']['count']} rescue today = {'count' => 0}
    today['count'] = DateTime.parse(@viewCount['last_hit'].to_json).today? ? today['count'] + 1 : 1
    @viewCount = {'last_hit' => DateTime.now, 'count' =>  @viewCount['count'] +1, 'today' => today }
    write_view_count
  end
  def write_view_count
    File.open("viewcount.json",'w') do |line|
      line.puts(@viewCount.to_json)
    end
  end
  def read_view_count
    begin
      File.open("viewcount.json").each do |line|
        @viewCount = JSON.parse(line)
      end
    rescue 
      @viewCount = {'last_hit' => DateTime.now, 'count' =>  0, 'today' => {'count' => 0} }
    end
  end

end
