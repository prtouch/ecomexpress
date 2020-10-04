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

    def request_data_pincode(opts)
      puts "================="
      puts opts[:params][:pinCode]
      puts opts[:extra]["profile"]
      puts opts[:extra]["profile"][:login_id]
      puts opts[:extra]["profile"][:license_key]
      data_pincode = "pincode="+opts[:params][:pinCode].to_s+"&username="+opts[:extra]["profile"][:login_id]+"&password="+opts[:extra]["profile"][:license_key]
      puts data_pincode
      return data_pincode 
     ##puts opts[:params][:pinCode]
     #envelope_ns_key = "#{namespace_key(:envelope)}"
     #builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
     #  xml[envelope_ns_key].Envelope(namespace_hash) {
     #    xml = header_xml(xml, opts[:wsa])
     #    xml = body_xml(xml, opts[:message], opts[:params], opts[:extra])
     #  }
     #end
    end


    def request_data_pincode(opts)
      puts "================="
      puts opts[:params][:pinCode]
      puts opts[:extra]["profile"]
      puts opts[:extra]["profile"][:login_id]
      puts opts[:extra]["profile"][:license_key]
      data_pincode = "pincode="+opts[:params][:pinCode].to_s+"&username="+opts[:extra]["profile"][:login_id]+"&password="+opts[:extra]["profile"][:license_key]
      puts data_pincode
      return data_pincode 
     ##puts opts[:params][:pinCode]
     #envelope_ns_key = "#{namespace_key(:envelope)}"
     #builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
     #  xml[envelope_ns_key].Envelope(namespace_hash) {
     #    xml = header_xml(xml, opts[:wsa])
     #    xml = body_xml(xml, opts[:message], opts[:params], opts[:extra])
     #  }
     #end
    end



    # input params
    # opts - Hash
    #
    # Fire XML request and return parsed response
    #
    # Returns Hash
#   def make_request_pincode(opts)
#     puts opts
#     puts "data"
#     body_data = request_data_pincode(opts)
#     #body = request_xml(opts)
#     #puts body.to_xml
#     response = request_ecx(opts[:url], body_data)
#     #response = request(opts[:url], body.to_xml)
#     response_return(response, opts[:message])
#   end

