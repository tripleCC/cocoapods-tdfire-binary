require 'cocoapods-tdfire-binary/binary_state_store'
require 'cocoapods-tdfire-binary/command/lint/lib'
require 'cocoapods-tdfire-binary/command/lint/spec'
module Pod
	class Command
		class Binary < Command
			class Lint < Binary
				self.abstract_command = true
				self.default_subcommand = 'lib'
				self.summary = '二进制lint操作'
				self.description = <<-DESC
							二进制lint操作
				DESC
			end
		end
	end
end