module Pod
	module Tdfire
		class BinaryUrlManager
			HOST = "http://iosframeworkserver-shopkeeperclient.cloudapps.2dfire.com"

			def self.pull_url_for_pod_version(pod, version)
				HOST + "/getframework/PRODUCTION/#{pod}/#{version}"
			end

			def self.get_pull_url_for_pod_version(pod, version)
				command = "curl #{pull_url_for_pod_version(pod, version)} > #{pod}.framework.zip"

				run_curl command
			end

			def self.push_url
				HOST + "/upload" #+ param
			end

			def self.post_push_url(name, version, path, commit = nil, commit_hash = nil)
				param = %Q[-F "frameworkName=#{name}" -F "version=#{version}" -F "environment=PRODUCTION" -F "changelog=#{commit}" -F "featureName=#{commit}" -F "framework=@#{path}" -F "commitHash=#{commit_hash}"]
				command = "curl #{push_url} #{param}"

				run_curl command
			end

			def self.delete_binary(name, version)
				command = "curl -X 'DELETE' #{HOST}/framework/PRODUCTION/#{name}/#{version} -O -J"
				run_curl command
			end

			def self.list_binary()
				command = "curl #{HOST}/frameworks\?allinfo=true"
				run_curl command
			end

			def self.search_binary(name)
				command = "curl #{HOST}/framework/#{name}"
				run_curl command
			end

			def self.run_curl(command)
				Pod::UI.message "CURL: \n" + command + "\n"

				`#{command} -s`
			end

			def self.private_cocoapods_url
				"git@git.2dfire-inc.com:ios/cocoapods-spec.git"
				# "git@git.2dfire-inc.com:qingmu/private_cocoapods.git"
			end

			def self.template_lib_url
				"git@git.2dfire-inc.com:ios/binary-pod-template.git"
			end
		end
	end
end
