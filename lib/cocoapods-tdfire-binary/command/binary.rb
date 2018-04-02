require 'cocoapods-tdfire-binary/command/lint'
require 'cocoapods-tdfire-binary/command/package'
require 'cocoapods-tdfire-binary/command/publish'
require 'cocoapods-tdfire-binary/command/pull'
require 'cocoapods-tdfire-binary/command/push'

module Pod
	class Command
		class Binary < Command
			self.abstract_command = true
			self.summary = '2Dfire 二进制工具库'
			self.description = <<-DESC
				2Dfire 二进制工具库，提供打包、lint、推送、拉取、发布等命令
      DESC

			FIRE_FLAG = "private"

      def first_podspec
      	Dir["#{Dir.pwd}/*.podspec"].first
			end

			def fire_sources
				config.sources_manager.all.select do |source|
					source.url.downcase.include? FIRE_FLAG
				end
			end
		end
	end
end