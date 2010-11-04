require "rubygems"
require "savon"
require "json"
require "sinatra"

helpers do
  attr_accessor :client
  def dsb(method_name, &block)
    @client ||= Savon::Client.new "http://193.28.147.179/stationdeparture/Service.asmx?WSDL"
    soap_response = @client.call method_name, &block
    soap_response.to_hash["#{method_name}_response".to_sym]["#{method_name}_result".to_sym]
  end
end

get '/' do
  'You might want to try <a href="stations">stations</a> instead.'
end

get '/stations' do
  result = dsb(:get_stations)
  stations = result[:station]
  content_type 'application/json'
  stations.to_json
end

get '/station_queue/:uic' do |uic|
  result = dsb(:get_station_queue) {|s| s.body = {"wsdl:request" => {"wsdl:UICNumber" => uic}}}
  raise Sinatra::NotFound if result[:status][:status_number] == "1"
  trains = result[:trains] ? result[:trains][:train_object] : []
  content_type 'application/json'
  trains.to_json
end
