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

      def first_podspec
      	Dir["#{Dir.pwd}/*.podspec"].first
      end
		end
	end
end