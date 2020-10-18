module Ecomexpress
  class PincodeService < Base
    def initialize(details)
      @pincode = details[:pincode]
      @profile = profile_hash({api_type: 'S', version: '1.3'}, details[:creds])
      @mode = details[:mode]
    end

    def request_url
      if @mode == 'prod'
        #'http://netconnect.ecomexpress.com/Ver1.8/ShippingAPI/Finder/ServiceFinderQuery.svc'
        #'http://netconnect.ecomexpress.com/Ver1.8/ShippingAPI/Finder/ServiceFinderQuery.svc'
        #'https://api.ecomexpress.in/apiv2/pincode/'
        'https://clbeta.ecomexpress.in/apiv2/pincode/'
      else
        'https://clbeta.ecomexpress.in/apiv2/pincode/'
      end
    end

    def response
      wsa = 'http://tempuri.org/IServiceFinderQuery/GetServicesforPincode'
      puts request_url
      opts = {message: 'GetServicesforPincode', wsa: wsa, params: {pinCode: @pincode}, extra: {'profile' => @profile}, url: request_url}
      make_request(opts, "pincode")
    end
  end
end
