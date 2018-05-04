require 'cocoapods-tdfire-binary/binary_config'

module Pod
	module Tdfire
		class BinaryUrlManager
      def self.pull_url_for_pod_version(pod, version)
				host + "/download/#{pod}/#{version}"
			end

			def self.get_pull_url_for_pod_version(pod, version)
				command = "curl #{pull_url_for_pod_version(pod, version)} > #{pod}.framework.zip"

				run_curl command
			end

			def self.push_url
        host + "/upload" #+ param
			end

			def self.post_push_url(name, version, path, commit = nil, commit_hash = nil)
				param = %Q[-F "frameworkName=#{name}" -F "version=#{version}" -F "changelog=#{commit}" -F "featureName=#{commit}" -F "framework=@#{path}" -F "commitHash=#{commit_hash}"]
				command = "curl #{push_url} #{param}"

				run_curl command
			end

			def self.delete_binary(name, version)
				command = "curl -X 'DELETE' #{host}/framework/#{name}/#{version} -O -J"
				run_curl command
			end

			def self.list_binary()
				command = "curl #{host}/frameworks\?allinfo=true"
				run_curl command
			end

			def self.search_binary(name)
				command = "curl #{host}/framework/#{name}"
				run_curl command
			end

			def self.run_curl(command)
				Pod::UI.message "CURL: \n" + command + "\n"

				result = `#{command} -s -m 5`

				raise Pod::Informative, "执行 #{command} 失败，查看网络或者 binary_config.yml 配置." if $?.exitstatus != 0

				result
			end

      def self.host
        BinaryConfig.instance.server_host
      end

			def self.private_cocoapods_url
        BinaryConfig.instance.repo_url
			end

			def self.template_lib_url
        BinaryConfig.instance.template_url
			end
		end
	end
end
