module Ecomexpress
  class AwbFetch < Base
    def initialize(details)
      @count = details[:count]
      @type = details[:type]
      @profile = profile_hash({api_type: 'S', version: '1.3'}, details[:creds])
    end

    def request_url
      if @mode == 'prod'
        #'http://netconnect.ecomexpress.com/Ver1.8/ShippingAPI/Finder/ServiceFinderQuery.svc'
        #'http://netconnect.ecomexpress.com/Ver1.8/ShippingAPI/Finder/ServiceFinderQuery.svc'
        #'https://api.ecomexpress.in/apiv2/fetch_awb/'
        'https://api.ecomexpress.in/apiv2/fetch_awb/'
      else
        'https://api.ecomexpress.in/apiv2/fetch_awb/'
        #'https://clbeta.ecomexpress.in/apiv2/fetch_awb/'
      end
    end

    def response
      wsa = 'http://tempuri.org/IServiceFinderQuery/GetServicesforPincode'
      #puts request_url
      opts = {message: 'GetServicesforPincode', wsa: wsa, params: {count: @count, type:@type}, extra: {'profile' => @profile}, url: request_url}
      make_request(opts, "fetch_awb")
    end
  end
end
