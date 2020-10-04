module Ecomexpress
  class Shipment < Base
    def initialize(details)
      p details
      @shipper = shipper_hash(details[:shipper_details])
      @consignee = consignee_hash(details[:consignee_details])
      @services = services_hash(details[:services])
      @profile = profile_hash({api_type: 'S', version: '1.3'}, details[:creds])
      @mode = details[:mode]
    end

    def request_url
      if @mode == 'prod'
        'https://netconnect.ecomexpress.com/Ver1.8/ShippingAPI/WayBill/WayBillGeneration.svc'
      else
        'http://netconnect.ecomexpress.com/Ver1.8/Demo/ShippingAPI/WayBill/WayBillGeneration.svc'
      end
    end

    def response
      wsa = 'http://tempuri.org/IWayBillGeneration/GenerateWayBill'
      # TODO: ITS A HACK NEEDS TO BE REMOVED
      # TODO: NEED TO REWRITE TO USE NAMESPACES DEFINED IN NAMESPACES FUNCTION
      params = {'Request' => {'ns4:Consignee' => @consignee, 'ns4:Services' => @services, 'ns4:Shipper' => @shipper}}
      opts = {message: 'GenerateWayBill', wsa: wsa, params: params, extra: {'Profile' => @profile}, url: request_url}
      make_request(opts, "shipment")
    end

    private
    def shipper_hash(details)
      params = {}
      address_array = multi_line_address(details[:address], 30)
      params['PICKUP_ADDRESS_LINE1'] = address_array[0]
      params['PICKUP_ADDRESS_LINE2'] = address_array[1]
      params['PICKUP_MOBILE'] = details[:customer_mobile]
      params['PICKUP_NAME'] = details[:customer_name]
      params['PICKUP_PINCODE'] = details[:customer_pincode]
      params['PICKUP_PHONE'] = details[:customer_telephone]
      params['RETURN_ADDRESS_LINE1'] = address_array[0]
      params['RETURN_ADDRESS_LINE2'] = address_array[1]
      params['RETURN_MOBILE'] = details[:customer_mobile]
      params['RETURN_NAME'] = details[:customer_name]
      params['RETURN_PINCODE'] = details[:customer_pincode]
      params['RETURN_PHONE'] = details[:customer_telephone]
      #params['CustomerAddress3'] = address_array[2]
      #params['CustomerCode'] = details[:customer_code]
      #params['CustomerEmailID'] = details[:customer_email_id]
      #params['IsToPayCustomer'] = details[:isToPayCustomer]
      #params['OriginArea'] = details[:origin_area]
      #params['Sender'] = details[:sender]
      #params['VendorCode'] = details[:vendor_code]
      params
    end

    def consignee_hash(details)
      params = {}
      address_array = multi_line_address(details[:address], 30)
      params['CONSIGNEE_ADDRESS1'] = address_array[0]
      params['CONSIGNEE_ADDRESS2'] = address_array[1]
      params['CONSIGNEE_ADDRESS3'] = address_array[2]
      #params['ConsigneeAttention'] = details[:consignee_attention]
      params['MOBILE'] = details[:consignee_mobile]
      params['CONSIGNEE'] = details[:consignee_name]
      params['PINCODE'] = details[:consignee_pincode]
      params['TELEPHONE'] = details[:consignee_telephone]
      params['DESTINATION_CITY'] = ""
      params['STATE'] = ""
      #params["ADDONSERVICE"] = []
#      if details[:city]; params['DESTINATION_CITY'] = details[:city]
#      if details[:state]; params['STATE'] = details[:state]
      params
    end

    def services_hash(details)
      p "========"
      p details
      params = {}
      #ACTUAL_WEIGHT in KG
      params['ACTUAL_WEIGHT'] = details[:actual_weight]
      params['COLLECTABLE_VALUE'] = details[:collactable_amount]
      params['Commodity'] = commodites_hash(details[:commodities])
      params['ITEM_DESCRIPTION'] = commodites_hash(details[:commodities])
      params['CreditReferenceNo'] = details[:credit_reference_no]
      params['DECLARED_VALUE'] = details[:declared_value]
      #params['Dimensions'] = dimensions_hash(details[:dimensions])
      params['LENGTH'] = 1
      params['BREADTH'] = 1
      params['HEIGHT'] = 1
      params['VOLUMETRIC_WEIGHT'] = 1
      if details[:dimensions]
	  # dimensions in CM
          #  if details[:dimensions][0][:length]; params['LENGTH'] = details[:dimensions][0][:length]
          #  if details[:dimensions][0][:breadth]; params['BREADTH'] = details[:dimensions][0][:breadth]
          #  if details[:dimensions][0][:height]; params['HEIGHT'] = details[:dimensions][0][:height]
      end
      params["ADDITIONAL_INFORMATION"] = {}
      params["ADDITIONAL_INFORMATION"]["INVOICE_NUMBER"] = details[:invoice_no]
      params['ORDER_NUMBER'] = details[:invoice_no]
      params['PackType'] = details[:pack_type]
      params['PickupDate'] = details[:pickup_date]
      params['PickupTime'] = details[:pickup_time]
      params['PIECES'] = details[:piece_count]
      params['ProductCode'] = details[:product_code]
      params['RegisterPickup'] = details[:register_pickup]
      params['PRODUCT'] = details[:product_type]
      params['ProductType'] = details[:product_type]
      params['SubProductCode'] = details[:sub_product_code]
      params['SpecialInstruction'] = details[:special_instruction]
      params['PDFOutputNotRequired'] = details[:p_d_f_output_not_required]
      params['PrinterLableSize'] = details[:printer_label_size]
      params
    end

    def dimensions_hash(details)
      params = []
      details.each do |d|
        params << {'Dimension' => {'Breadth' => d[:breadth], 'Height' => d[:height], 'Length' => d[:length], 'Count' => d[:count]} }
      end
      params
    end

    def commodites_hash(details)
      params = {}
      details.each_with_index {|d, i| params["CommodityDetail#{i+1}"] = d}
      params
    end
  end
end
