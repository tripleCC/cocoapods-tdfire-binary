require 'curb'

module Tdfire	
	class BinaryUrlManager
		HOST = "http://iosframeworkserver-shopkeeperclient.cloudapps.2dfire.com"

		def self.pull_url_for_pod_version(pod, version)
    	HOST + "/getframework/PRODUCTION/#{pod}/#{version}"
    end

    def self.push_url
    	# param = <<~EOF
    	# -F "frameworkName=#{name}" 
	    # -F "version=#{version}" 
	    # -F "environment=PRODUCTION" 
	    # -F "changelog=#{commit}" 
	    # -F "featureName=#{commit}" 
	    # -F "framework=@#{path}" 
	    # -F "commitHash=#{commit_hash}"
    	# EOF

    	HOST + "/upload" #+ param
    end

    def self.post_push_url(name, version, path, commit = nil, commit_hash = nil)
    	param = {
    		:frameworkName = name,
    		:version = version,
    		:environment = "PRODUCTION",
    		:changelog = commit,
    		:featureName = commit,
    		:framework = "@#{path}"
    		:commitHash = commit_hash
    	}
    	Curl.post("http://www.google.com/", param)
    end

    def self.private_cocoapods_url
    	"git@git.2dfire-inc.com:ios/cocoapods-spec.git"
    end
	end
end