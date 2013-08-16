# fix oauth-ruby, it can't signature multipart-form  
require 'oauth/request_proxy/base'

module OAuth::RequestProxy::Net
  module HTTP
    class HTTPRequest < OAuth::RequestProxy::Base

    private

      def all_parameters
        request_params = CGI.parse(query_string)
        if options[:parameters]
          options[:parameters].each do |k,v|
            if request_params.has_key?(k)
              request_params[k] << v
            else
              request_params[k] = [v].flatten
            end
          end
        end
puts "#-------------options[:multipart_form_params]---"
puts YAML::dump(options[:multipart_form_params])
puts "#-------------options---"
puts YAML::dump(options)
        if options[:multipart_form_params]
          options[:multipart_form_params].each do |k,v|
            if request_params.has_key?(k)
              request_params[k] << v
            else
              request_params[k] = [v].flatten
            end
          end
        end
puts "#-------------request_params---"
puts YAML::dump(request_params)
        request_params
      end

    end
  end
end
  
