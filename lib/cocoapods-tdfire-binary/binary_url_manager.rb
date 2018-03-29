module Tdfire	
	class BinaryUrlManager
		HOST = "http://iosframeworkserver-shopkeeperclient.cloudapps.2dfire.com"

		def self.pull_url_for_pod_version(pod, version)
    	HOST + "/getframework/PRODUCTION/#{pod}/#{version}"
    end

    def self.push_url
    	HOST + "/upload"
    end
	end
end