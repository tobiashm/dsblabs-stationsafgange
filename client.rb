# encoding: utf-8
require "savon"
require "json"
require "sinatra"

helpers do
  attr_accessor :client
  def dsb(method_name, arguments = {})
    @client ||= Savon.client(wsdl: "http://traindata.dsb.dk/stationdeparture/Service.asmx?WSDL")
    soap_response = @client.call(method_name, arguments)
    soap_response.to_hash["#{method_name}_response".to_sym]["#{method_name}_result".to_sym]
  end

  def filter(stations)
    params.each_key do |key|
      stations.reject! { |station| station[key.to_sym] != params[key] }
    end
  end

  def add_queue_link(stations)
    stations.each { |s| s[:queue] = "#{request.base_url}/queue?uic=#{s[:uic]}" }
  end
end

get '/' do
  <<-EOC
    <!DOCTYPE HTML>
    <title>
      RESTful gateway for DSB Labs
    </title>
    <h1>
      RESTful gateway for <a href="http://www.dsb.dk/dsb-labs/webservice-stationsafgange/">DSB Labs – Webservice: Stationsafgange</a>
    </h1>
    <p>
      <em>All data is returned as JSON</em>
    </p>
    <p>
      You might want to see the <a href="stations">list of stations</a>.
    </p>
    <form action="queue">
      <p>
        Or find departures etc. for a given station.
        <label>Station UIC: <input type="text" name="uic"></label>
        <input type="submit">
      </p>
    </form>
  EOC
end

get '/stations' do
  result = dsb(:get_stations)
  stations = result[:station]
  filter(stations)
  add_queue_link(stations)
  content_type 'application/json'
  stations.to_json
end

get '/queue' do
  redirect_to '/' unless params[:uic]
  result = dsb(:get_station_queue, message: { "request" => { "UICNumber" => params[:uic] } })
  fail Sinatra::NotFound if result[:status][:status_number] == "1"
  trains = result[:trains] && result[:trains][:queue] || []
  content_type 'application/json'
  trains.to_json
end
