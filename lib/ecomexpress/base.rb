require 'nokogiri'
require 'httparty'
require 'nori'

module Ecomexpress
  class Base
    private

    # input params
    # details - Hash
    # creds - Hash
    #
    # Creates profile hash
    #
    # Return Hash
    def profile_hash(details, creds)
      params = {}
      params[:api_type] = details[:api_type]
      params[:license_key] = creds[:license_key]
      params[:login_id] = creds[:login_id]
      params[:version] = details[:version]
      params
    end

    # input params - none
    #
    # Creates hash containing required namespaces
    #
    # Returns Hash
    def namespaces
      ns = {}
      ns[:envelope] = {key:'env', value: 'http://www.w3.org/2003/05/soap-envelope'}
      ns[:content]  = {key:'ns1', value: 'http://tempuri.org/'}
      ns[:profile]  = {key:'ns2', value: 'http://schemas.datacontract.org/2004/07/SAPI.Entities.Admin'}
      ns[:wsa]      = {key:'ns3', value: 'http://www.w3.org/2005/08/addressing'}
      ns[:shipment] = {key:'ns4', value: 'http://schemas.datacontract.org/2004/07/SAPI.Entities.WayBillGeneration'}
      ns[:pickup]   = {key:'ns5', value: 'http://schemas.datacontract.org/2004/07/SAPI.Entities.Pickup'}
      ns
    end

    # input params - none
    #
    # Creates hash with xml styled namespace key and value
    #
    # Returns Hash
    def namespace_hash
      opt = {}
      namespaces.each do |type, attrs|
        key = "xmlns:#{attrs[:key]}"
        opt[key] = attrs[:value]
      end
      opt
    end

    # input params
    # name - symbol
    #
    # Provides key for a given namespace block
    #
    # Returns String
    def namespace_key(name)
      namespaces[name][:key]
    end

    # input params
    # xml - Nokogiri::XML::Builder
    # values - Hash
    #
    # Appends Profile XML Block
    #
    # Returns Nokogiri::XML::Builder
    def profile_xml(xml, values)
      ns_key = "#{namespace_key(:profile)}"
      xml[ns_key].Api_type values[:api_type]
      xml[ns_key].LicenceKey values[:license_key]
      xml[ns_key].LoginID values[:login_id]
      xml[ns_key].Version values[:version]
      xml
    end

    # input params
    # xml - Nokogiri::XML::Builder
    # wsa - string
    #
    # Appends Header XML Block
    #
    # Returns Nokogiri::XML::Builder
    def header_xml(xml, wsa)
      xml.Header {
        xml["#{namespace_key(:wsa)}"].Action(wsa, "#{namespace_key(:envelope)}:mustUnderstand" => true)
      }
      xml
    end

    # input params
    # xml - Nokogiri::XML::Builder
    # params - Hash
    #
    # Transform Hash to XML
    #
    # Returns Nokogiri::XML::Builder
    def hash_xml(xml, params)
      params.each do |key, value|
        xml = xml_key_value(key, value, xml)
      end
      xml
    end

    # TODO: ITS A HACK NEEDS TO BE REMOVED
    # input params
    # key - string
    #
    # Removes last letter from string
    #
    # Returns String
    def singular(key)
      key = key[0..-2]
    end

    def xml_key_value(key, value, xml)
      if value.is_a?(Hash)
        xml.send(key) do |xml|
          value.each {|inner_key, inner_values| xml = xml_key_value(inner_key, inner_values, xml)}
        end
      elsif value.is_a?(Array)
        xml.send(key) do |xml|
          value.each do |single_value|
            xml = hash_xml(xml, single_value)
          end
        end  
      else
        xml.send(key, value)
      end
      xml
    end

    # input params
    # xml - Nokogiri::XML::Builder
    # message - String
    # params - Hash
    # extra - Hash
    #
    # Appends Body XML Block
    #
    # Returns Nokogiri::XML::Builder
    def body_xml(xml, message, params, extra)
      content_ns_key = "#{namespace_key(:content)}"
      xml.Body {
        xml[content_ns_key].send(message) do |xml|
          hash_xml(xml, params)
          extra.each do |key, value|
            xml[content_ns_key].send(key) { profile_xml(xml, value)} if key.downcase == 'profile'
          end
        end
      }
      xml
    end

    # input params
    # opts - Hash
    #
    # Create XML Request
    #
    # Returns Nokogiri::XML::Builder
    def request_xml(opts)
      envelope_ns_key = "#{namespace_key(:envelope)}"
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml[envelope_ns_key].Envelope(namespace_hash) {
          xml = header_xml(xml, opts[:wsa])
          xml = body_xml(xml, opts[:message], opts[:params], opts[:extra])
        }
      end
    end

    def request_data_fetch_awb(opts)
      data_pincode = "type="+opts[:params][:type].to_s+"&count="+opts[:params][:count].to_s+"&username="+opts[:extra]["profile"][:login_id]+"&password="+opts[:extra]["profile"][:license_key]
      return data_pincode 
    end


    def request_data_shipment(opts)
      awb_request = {type: "ppd", count: 1, mode: 'development', creds: {license_key: opts[:extra]["Profile"][:license_key], login_id: opts[:extra]["Profile"][:login_id]}}
      awb_prepare = Ecomexpress::AwbFetch.new(awb_request)
      awb = awb_prepare.response
      puts "===="
      puts opts[:params]["Request"]["ns4:Consignee"]
      puts opts[:params]["Request"]["ns4:Services"]
      puts opts[:params]["Request"]["ns4:Shipper"]
      puts "$$$$$$$$$$$$$$$$"

      collectable_value = opts[:params]["Request"]["ns4:Services"]["CollectableAmount"]
      if not collectable_value.is_a? Numeric
	  collectable_value = 0
      end

      p opts[:params]["Request"]["ns4:Services"]
      p "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

      if  opts[:params]["Request"]["ns4:Shipper"]["IsReversePickup"] == true
          a = [{
            "AWB_NUMBER": awb.to_s,
            "ORDER_NUMBER": opts[:params]["Request"]["ns4:Services"]["InvoiceNo"],
            "PRODUCT": "REV",
            "REVPICKUP_NAME": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeName"],
            "REVPICKUP_ADDRESS1": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeAddress1"],
            "REVPICKUP_ADDRESS2": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeAddress2"],
            "REVPICKUP_ADDRESS3": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeAddress3"],
            "REVPICKUP_CITY": "GURGAON",
            "REVPICKUP_PINCODE": opts[:params]["Request"]["ns4:Consignee"]["ConsigneePincode"].to_s,
            "REVPICKUP_STATE": "DL",
            "REVPICKUP_MOBILE": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeMobile"].to_s,
            "REVPICKUP_TELEPHONE": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeTelephone"].to_s,
            "ITEM_DESCRIPTION": opts[:params]["Request"]["ns4:Services"]["Commodity"]["CommodityDetail1"],
            "PIECES": opts[:params]["Request"]["ns4:Services"]["PieceCount"].to_s,
            "COLLECTABLE_VALUE": 0,
            "DECLARED_VALUE": opts[:params]["Request"]["ns4:Services"]["DeclaredValue"].to_s,
            "ACTUAL_WEIGHT": opts[:params]["Request"]["ns4:Services"]["ActualWeight"].to_s,
            "VOLUMETRIC_WEIGHT": 0.to_s,
            "LENGTH": 1.to_s,
            "BREADTH": 1.to_s,
            "HEIGHT": 1.to_s,
            "DROP_NAME": opts[:params]["Request"]["ns4:Shipper"]["CustomerName"] ,
            "DROP_ADDRESS_LINE1": opts[:params]["Request"]["ns4:Shipper"]["CustomerAddress1"],
            "DROP_ADDRESS_LINE2": "",
            "DROP_PINCODE": opts[:params]["Request"]["ns4:Shipper"]["CustomerPincode"],
            "DROP_PHONE": opts[:params]["Request"]["ns4:Shipper"]["CustomerTelephone"].to_s,
            "DROP_MOBILE": opts[:params]["Request"]["ns4:Shipper"]["CustomerMobile"].to_s,
            "DG_SHIPMENT": false
           #"ADDITIONAL_INFORMATION": {
           #        "essentialProduct": "N",
           #        "OTP_REQUIRED_FOR_DELIVERY": "N",
           #        "DELIVERY_TYPE": "",
           #        "SELLER_TIN": "",
           #        "INVOICE_NUMBER": opts[:params]["Request"]["ns4:Services"]["InvoiceNo"],
           #        "INVOICE_DATE": "",
           #}
            }]
         
      else 
          a = [{
            "AWB_NUMBER": awb.to_s,
            "ORDER_NUMBER": opts[:params]["Request"]["ns4:Services"]["InvoiceNo"],
            "PRODUCT": "PPD",
            "CONSIGNEE": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeName"],
            "CONSIGNEE_ADDRESS1": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeAddress1"],
            "CONSIGNEE_ADDRESS2": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeAddress2"],
            "CONSIGNEE_ADDRESS3": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeAddress3"],
            "DESTINATION_CITY": "GURGAON",
            "PINCODE": opts[:params]["Request"]["ns4:Consignee"]["ConsigneePincode"].to_s,
            "STATE": "DL",
            "MOBILE": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeMobile"].to_s,
            "TELEPHONE": opts[:params]["Request"]["ns4:Consignee"]["ConsigneeTelephone"].to_s,
            "ITEM_DESCRIPTION": opts[:params]["Request"]["ns4:Services"]["Commodity"]["CommodityDetail1"],
            "PIECES": opts[:params]["Request"]["ns4:Services"]["PieceCount"].to_s,
            "COLLECTABLE_VALUE": collectable_value.to_s,
            "DECLARED_VALUE": opts[:params]["Request"]["ns4:Services"]["DeclaredValue"].to_s,
            "ACTUAL_WEIGHT": opts[:params]["Request"]["ns4:Services"]["ActualWeight"].to_s,
            "VOLUMETRIC_WEIGHT": 0.to_s,
            "LENGTH": 1.to_s,
            "BREADTH": 1.to_s,
            "HEIGHT": 1.to_s,
            "PICKUP_NAME": opts[:params]["Request"]["ns4:Shipper"]["CustomerName"] ,
            "PICKUP_ADDRESS_LINE1": opts[:params]["Request"]["ns4:Shipper"]["CustomerAddress1"],
            "PICKUP_ADDRESS_LINE2": "",
            "PICKUP_PINCODE": opts[:params]["Request"]["ns4:Shipper"]["CustomerPincode"],
            "PICKUP_PHONE": opts[:params]["Request"]["ns4:Shipper"]["CustomerTelephone"].to_s,
            "PICKUP_MOBILE": opts[:params]["Request"]["ns4:Shipper"]["CustomerMobile"].to_s,
            "RETURN_NAME": opts[:params]["Request"]["ns4:Shipper"]["CustomerName"] ,
            "RETURN_ADDRESS_LINE1": opts[:params]["Request"]["ns4:Shipper"]["CustomerAddress1"],
            "RETURN_ADDRESS_LINE2": "",
            "RETURN_PINCODE": opts[:params]["Request"]["ns4:Shipper"]["CustomerPincode"].to_s,
            "RETURN_PHONE": opts[:params]["Request"]["ns4:Shipper"]["CustomerTelephone"].to_s,
            "RETURN_MOBILE": opts[:params]["Request"]["ns4:Shipper"]["CustomerMobile"].to_s,
            "DG_SHIPMENT": false,
           #"ADDITIONAL_INFORMATION": {
           #        "essentialProduct": "N",
           #        "OTP_REQUIRED_FOR_DELIVERY": "N",
           #        "DELIVERY_TYPE": "",
           #        "SELLER_TIN": "",
           #        "INVOICE_NUMBER": opts[:params]["Request"]["ns4:Services"]["InvoiceNo"],
           #        "INVOICE_DATE": "",
           #}
            }]
      end
      p "JSON.dump(a)", JSON.dump(a)

      data_pincode = "json_input=" + JSON.dump(a) + "&username="+opts[:extra]["Profile"][:login_id]+"&password="+opts[:extra]["Profile"][:license_key]
      p "data_pincode", data_pincode
      return data_pincode 
    end


    def request_data_pincode(opts)
      data_pincode = "pincode="+opts[:params][:pinCode].to_s+"&username="+opts[:extra]["profile"][:login_id]+"&password="+opts[:extra]["profile"][:license_key]
      return data_pincode 
    end


    # input params
    # opts - Hash
    #
    # Fire XML request and return parsed response
    #
    # Returns Hash
    def make_request(opts, request_type)
      if request_type == "pincode"
          body = request_data_pincode(opts)
      elsif request_type == "fetch_awb"
          body = request_data_fetch_awb(opts)
      elsif request_type == "shipment"
          body = request_data_shipment(opts)
      elsif request_type == "cancel"
          body = request_data_cancel(opts)
      end
      response = request(opts[:url], body)
      if request_type == "pincode"
          response_return(response, opts[:message])
      elsif request_type == "fetch_awb"
          response_return_awb_fetch(response, opts[:message])
      elsif request_type == "cancel"
          response_return_cancel(response, opts[:message])
      elsif request_type == "shipment"
          response_return_shipment(response, opts[:message])
      end
    end

    def response_return_cancel(response, message)
      response_hash = {error: false, error_text: ''}
      if response["success"] == "yes"
	  response_hash["awb"] = response["awb"][0]
      end
    end


    def response_return_shipment(response, message)
      response_hash = {error: false, error_text: ''}
      if response["success"] == "yes"
	  response_hash["awb"] = response["awb"][0]
      end
    end


    def response_return_awb_fetch(response, message)
      response_hash = {error: false, error_text: ''}
      if response["success"] == "yes"
	  response_hash["awb"] = response["awb"][0]
      end
    end

    def response_return(response, message)
      response_hash = {error: false, error_text: ''}
     # p response[0]
      if response.length() == 0
        response_hash[:error] = true
        response_hash[:error_text] = "Pincode not serviceable"
      elsif response[0]["active"] == false
        response_hash[:error] = true
        response_hash[:error_text] = "Pincode not serviceable"
      end
      response_hash
    end

    # input params
    # prefix - String
    # content - Hash
    #
    # Removes Junk content from response
    #
    # Returns Hash
    def required_content(prefix, content)
      if content[:fault].nil?
        prefix_s = prefix.snakecase
        keys = (prefix_s + '_response').to_sym, (prefix_s + '_result').to_sym
        return content[keys[0]][keys[1]]
      else
        return {error: true, error_text: content[:fault]}
      end
    end

    # input params
    # url - String
    # body - String
    #
    # Fires request and returns response
    #
    # Returns Hash
    def request(url, body)
      #res = HTTParty.post(url, body: body, headers: {'Content-Type' => 'application/soap+xml; charset="utf-8"'}, :verify => false)
      res = HTTParty.post(url, body: body, headers: {'Content-Type' => 'application/soap+xml; charset="utf-8"'}, :verify => false)
      p "response is: #{res}. response body is: #{res.body} for url: #{url}"
      content = JSON.parse(res.body)
    end

    # input params
    # xml - String
    #
    # Converts XML to Hash
    #
    # Returns Hash
    def xml_hash(xml)
      nori = Nori.new(strip_namespaces: true, :convert_tags_to => lambda { |tag| tag.snakecase.to_sym })
      nori.parse(xml)
    end

    # input params
    # address - String
    # line_length - Integer
    #
    # Splits address into array by count of characters
    #
    # Returns Array
    def multi_line_address(address, line_length)
      multi_line_address_block = []
      i = 0
      address.split(/[ ,]/).each do |s|
        if multi_line_address_block[i].blank?
          multi_line_address_block[i] = s
        elsif (multi_line_address_block[i].length + s.length < line_length)
          multi_line_address_block[i] += ' ' + s
        else
          i += 1
          multi_line_address_block[i] = s
        end
      end
      multi_line_address_block
    end
  end
end
