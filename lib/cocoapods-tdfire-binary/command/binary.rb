require 'cocoapods-tdfire-binary/command/lint'
require 'cocoapods-tdfire-binary/command/package'
require 'cocoapods-tdfire-binary/command/publish'
require 'cocoapods-tdfire-binary/command/pull'
require 'cocoapods-tdfire-binary/command/push'
require 'cocoapods-tdfire-binary/command/assemble'
require 'cocoapods-tdfire-binary/command/lib'
require 'cocoapods-tdfire-binary/command/delete'
require 'cocoapods-tdfire-binary/command/search'
require 'cocoapods-tdfire-binary/command/list'
require 'cocoapods-tdfire-binary/command/init'
require 'cocoapods-tdfire-binary/binary_config'

module Pod
	class Command
		class Binary < Command
			self.abstract_command = true
			self.summary = '2Dfire 二进制工具库'
			self.description = <<-DESC
				2Dfire 二进制工具库，提供打包、lint、推送、拉取、发布等命令
      DESC

			def binary_config
				Pod::Tdfire::BinaryConfig.instance
			end

      def first_podspec
      	Dir["#{Dir.pwd}/*.podspec"].first
			end

			def private_sources
				binary_config.private_sources
			end
		end
	end
end