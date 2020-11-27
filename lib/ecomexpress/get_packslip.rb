require 'prawn'
require 'prawn/table'
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/ascii_outputter'
require 'barby/outputter/svg_outputter'
require 'barby/outputter/png_outputter'
require 'prawn-svg'
#require 'prawn-png'



module Ecomexpress
  class GetPackslip < Base
    def initialize(details, awb_no)
      @awb_no = awb_no 
      @shipper = shipper_hash(details[:shipper_details])
      @consignee = consignee_hash(details[:consignee_details])
      @services = services_hash(details[:services])
      @profile = profile_hash({api_type: 'S', version: '1.3'}, details[:creds])
      @mode = details[:mode]
    end


#   def request_url
#     if @mode == 'prod'
#       'https://clbeta.ecomexpress.in/apiv2/manifest_awb/'
#       if @services[:shipment_method] == true 
#           #'https://api.ecomexpress.in/apiv2/manifest_awb_rev_v2/'
#           'https://clbeta.ecomexpress.in/apiv2/manifest_awb_rev_v2/'
#       end
#     else
#       'https://clbeta.ecomexpress.in/apiv2/manifest_awb/'
#       if @services[:shipment_method] == true 
#           'https://clbeta.ecomexpress.in/apiv2/manifest_awb_rev_v2/'
#       end
#     end
#   end

    def generate_packslip
      p "generate_packslip start"
      receipt_pdf = Prawn::Document.new
      product_type = ""
      if @services['SubProductCode'] == "C" 
          product_type = "[COD]"
      end
      if @services['SubProductCode'] == "P" 
          product_type = "[PPD]"
      end
      if @shipper['IsReversePickup'] == true
          product_type = "[REV]"
      end



      p "Barby start"
      barcode = Barby::Code128.new(@awb_no)
      #File.open('/tmp/barcode'+ @awb_no +'.svg', 'w'){|f| f.write barcode.to_svg(height: 70, width: 260, margin: 0) }
     #File.open('barcode'+ @awb_no +'.png', 'w'){|f| f.write barcode.to_png(height: 70, width: 260, margin: 0) }
     #image_cells = []
     #img_file = File.new('barcode'+ @awb_no +'.png')
     #im_options = {:content => img_file, :dry_run => true, :bound => true, :align => :center}
     #img_cell = Prawn::Table::Cell::Image.new(self, im_options[:at] || [0, cursor], im_options)
     #img_cell.draw if !options[:dry_run]
      #image_cells << image_cell(:content => img_file, :dry_run => true, :bound => true, :align => :center)

      #table_data_top = [[product_type, 'ECOM EXPRESS', @awb_no]]
      #
      p "Table start"
      table_data_top = [[product_type, "ECOM EXPRESS", @awb_no]]
      table_data_shipper_name = [['Shipper : '+ @shipper['CustomerName'], 'order: ' + @services['InvoiceNo']]]
      table_data_consignee = [['Consignee Details', 'Order Details'],
                              [@consignee['ConsigneeName'], 'Item description: ' + @services["Commodity"]["CommodityDetail1"] ],
                              [@consignee['ConsigneeAddress1'], 'Quantity: ' + @services["PieceCount"].to_s   ],
                              [@consignee['ConsigneeAddress2'], 'Dimension: 1 * 1 * 1'  ],
                              [@consignee['ConsigneeAddress3'],  'Actual Weight: ' + @services["ActualWeight"].to_s],
                              ['Pin: ' + @consignee['ConsigneePincode'],  '' ],
                              ['City: ' + @consignee['City'], ''  ]
                              
                             ]
      table_data_return_inst = [['IF UNDELIVERED RETURN TO:']]
      #p @shipper
      customer_address1 = "" 
      customer_address2 = "" 
      customer_address3 = "" 
      p "CustomerAddress1 start"
      if @shipper['CustomerAddress1']
           customer_address1 = @shipper['CustomerAddress1']
      end

      if @shipper['CustomerAddress2']
           customer_address2 = @shipper['CustomerAddress2']
      end

      if @shipper['CustomerAddress3']
           customer_address3 = @shipper['CustomerAddress3']
      end


      #table_data_return_info = [[@shipper['CustomerName'] + ", " + customer_address1 + ", " + customer_address2 + ", " + customer_address3 + @shipper['CustomerPincode']]] 
      table_data_return_info = [[@shipper['CustomerName'] + ", " + customer_address1 + ", " + customer_address2 + ", " + customer_address3 + ", " + @shipper['CustomerPincode']  ]] 
      #receipt_pdf.svg barcode.to_svg, width: 30, height: 50
      p "SVG start"
      receipt_pdf.svg barcode.to_svg(height: 30, width: 300, margin: 0)

      p "Table write start"
      receipt_pdf.table table_data_top , cell_style: {border_width: 0, width: 150, padding: [5, 5, 5, 5], text_color: '373737', inline_format: true} do
           columns(1).align = :left
           columns(2).align = :center
           columns(-1).align = :right
      end 

      p "table_data_shipper_name write start"
      receipt_pdf.table table_data_shipper_name , cell_style: {border_width: 0, width: 225, padding: [5, 5, 5, 5], text_color: '373737', inline_format: true} do
           rows(0).border_top_width = 1 
           rows(0).border_bottom_width = 1 
           columns(0).border_left_width = 1 
           columns(1).border_right_width = 1 
           columns(0).align = :left
           columns(-1).align = :right
      end 

      p "table_data_consignee write start"
      receipt_pdf.table table_data_consignee , cell_style: {border_width: 0, width: 225, padding: [5, 5, 5, 5], text_color: '373737', inline_format: true} do
           rows(0).border_top_width = 1 
           rows(0).border_bottom_width = 1 
           rows(0).border_left_width = 1 
           rows(0).border_right_width = 1 
           columns(0).border_left_width = 1 
           columns(0).border_right_width = 1 
           columns(-1).border_left_width = 1 
           columns(-1).border_right_width = 1 
           columns(0).align = :left
           columns(-1).align = :left
           rows(-1).border_bottom_width = 1 
      end 

      p "table_data_return_inst write start"
      receipt_pdf.table table_data_return_inst , cell_style: {border_width: 1, width: 450, padding: [5, 5, 5, 5], text_color: '373737', inline_format: true} do
           columns(1).align = :center
      end 

      p "table_data_return_info write start"
      receipt_pdf.table table_data_return_info , cell_style: {border_width: 1, width: 450, padding: [5, 5, 5, 5], text_color: '373737', inline_format: true} do
           columns(1).align = :left
      end 



      p "file_write start"
      receipt_pdf.render_file '/tmp/my_pdf_file'+ @awb_no  + '.pdf'
      #pdf_data = receipt_pdf.render_to_string
      p "open file start"
      data = File.open('/tmp/my_pdf_file'+ @awb_no  + '.pdf').read
      #File.delete('/tmp/my_pdf_file'+ @awb_no  + '.pdf') if File.exist?('/tmp/my_pdf_file'+ @awb_no  + '.pdf')
      p "data file start"
      pdf_data = Base64.encode64(data)
     #decode_base64_content = Base64.decode64(pdf_data)
     #File.open("Output.txt", "wb") do |f|
     #  f.write(decode_base64_content)
     #end
     #p pdf_data 
      #make_request(opts, "shipment")
    end

    private
    def shipper_hash(details)
      params = {}
      address_array = multi_line_address(details[:address], 30)
      params['CustomerAddress1'] = address_array[0]
      params['CustomerAddress2'] = address_array[1]
      params['CustomerAddress3'] = address_array[2]
      params['CustomerCode'] = details[:customer_code]
      params['CustomerEmailID'] = details[:customer_email_id]
      params['CustomerMobile'] = details[:customer_mobile]
      params['CustomerName'] = details[:customer_name]
      params['CustomerPincode'] = details[:customer_pincode]
      params['CustomerTelephone'] = details[:customer_telephone]
      params['IsToPayCustomer'] = details[:isToPayCustomer]
      params['OriginArea'] = details[:origin_area]
      params['Sender'] = details[:sender]
      params['VendorCode'] = details[:vendor_code]
      params
    end

    def consignee_hash(details)
      params = {}
      address_array = multi_line_address(details[:address], 30)
      params['ConsigneeAddress1'] = address_array[0]
      params['ConsigneeAddress2'] = address_array[1]
      params['ConsigneeAddress3'] = address_array[2]
      params['ConsigneeAttention'] = details[:consignee_attention]
      params['ConsigneeMobile'] = details[:consignee_mobile]
      params['ConsigneeName'] = details[:consignee_name]
      params['ConsigneePincode'] = details[:consignee_pincode]
      params['ConsigneeTelephone'] = details[:consignee_telephone]
      params['City'] = details[:city]
      params['State'] = details[:state]
      params
    end

    def services_hash(details)
      params = {}
      params['ActualWeight'] = details[:actual_weight]
      params['CollectableAmount'] = details[:collectable_amount]
      params['Commodity'] = commodites_hash(details[:commodities])
      params['CreditReferenceNo'] = details[:credit_reference_no]
      params['DeclaredValue'] = details[:declared_value]
      #params['Dimensions'] = dimensions_hash(details[:dimensions])
      params['Dimensions'] = ""
      params['InvoiceNo'] = details[:invoice_no]
      params['PackType'] = details[:pack_type]
      params['PickupDate'] = details[:pickup_date]
      params['PickupTime'] = details[:pickup_time]
      params['PieceCount'] = details[:piece_count]
      params['ProductCode'] = details[:product_code]
      params['RegisterPickup'] = details[:register_pickup]
      params['ProductType'] = details[:product_type]
      params['SubProductCode'] = details[:sub_product_code]
      params['SpecialInstruction'] = details[:special_instruction]
      params['PDFOutputNotRequired'] = details[:p_d_f_output_not_required]
      params['PrinterLableSize'] = details[:printer_label_size]
      params['IsReversePickup'] = details[:is_reverse_pickup]
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
