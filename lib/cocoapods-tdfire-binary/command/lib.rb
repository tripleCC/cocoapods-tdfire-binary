require 'cocoapods-tdfire-binary/command/lib/create'

module Pod
	class Command
		class Binary < Command
			class Lib < Binary
			self.abstract_command = true
			self.default_subcommand = 'create'
			self.summary = '二进制模版库操作'
			self.description = <<-DESC
				二进制模版库操作
	DESC
	end
		end
	end
end