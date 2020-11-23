require 'httparty'
require 'nori'

module Ecomexpress
  class Tracking
    attr_reader :response

    def initialize(details)
      @numbers = details[:numbers].join(',')
      @scans = details[:scans]
      @license_key = details[:creds][:license_key]
      @loginid = details[:creds][:login_id]
    end

    def self.request_url
      #'https://clbeta.ecomexpress.in/track_me/api/mawbd/'
      'https://plapi.ecomexpress.in/track_me/api/mawbd/'
    end

    def request
      @response = make_request
    end
    
    private
    def make_request
      p "======"
      params = {handler: 'tnt', action: 'custawbquery', username: @loginid,
         awb: @numbers, password: @license_key,
        verno: 1.3, scan: @scans
      }
      p Tracking.request_url
      p params

      data_tracking = "awb="+ @numbers  + "&username="+ @loginid +"&password="+ @license_key 
      p data_tracking

      res = HTTParty.post(Tracking.request_url, body: data_tracking, headers: {'Content-Type' => 'application/soap+xml; charset="utf-8"'}, :verify => false)
      #p "response is: #{res}. response body is: #{res.body} for url: #{Tracking.request_url}"

      #request = HTTParty.get(Tracking.request_url, query: params, verify: false)
      #response_return(request.body)
      response_return(res.body)
    end

    def response_return(xml)
      nori = Nori.new(strip_namespaces: true)
      xml_hash = nori.parse(xml)
      p xml_hash["ecomexpress_objects"]
      # TODO need to implement error block
      response_hash = {error: false, error_text: ''}
      #response_hash[:results] = xml_hash['ShipmentData']['Shipment']
      #awb_no = data['@WaybillNo']
      #status = data['Status']
      #status_description: status,
      #status_code = data['StatusType']
      #expected_delivery_date: data['ExpectedDeliveryDate'

      if xml_hash["ecomexpress_objects"][0]["object"].is_a?(Hash)
        response_hash[:results]['@WaybillNo'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][0]
        response_hash[:results]['Status'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][10]
        response_hash[:results]['StatusType'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][14]
        response_hash[:results]['ExpectedDeliveryDate'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][18]
        response_hash[:results]['rts_shipment'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][22]
        response_hash[:results]['ref_awb'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][23]
        response_hash[:results]['rts_system_delivery_status'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][26]
        response_hash[:results]['rts_reason_code_number'] = xml_hash["ecomexpress_objects"][0]["object"][0]["field"][27]
        #response_hash[:results] = [response_hash[:results]]
      end
      response_hash
    end





  end
end
