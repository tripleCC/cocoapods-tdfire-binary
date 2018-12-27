require 'cocoapods-tdfire-binary/command/version/match'
module Pod
	class Command
		class Binary < Command
			class Version < Binary
				self.abstract_command = true
				self.default_subcommand = 'match'
				self.summary = '组件版本操作'
				self.description = <<-DESC
							组件版本操作
				DESC
			end
		end
	end
end