require 'net/http'
require 'json'
require 'date'
class MainpageController < ApplicationController
  def index
    @day_shift = params[:day_shift].to_i || 0
    @language = params[:language] || 'fi'
    @date = DateTime.now + @day_shift
    uri = URI("https://www.sodexo.fi/ruokalistat/output/daily_json/12812/#{@date.year}/#{@date.month.to_s.rjust(2, "0")}/#{@date.day.to_s.rjust(2, "0")}/#{@language}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri.path, 'Content-Type' => 'application/json')
    res = http.request(req)
    @sodexo_data = JSON.parse(res.body)["courses"]
    @json = res.body
    rescue => e
      puts "failed #{e}"

  end
end
