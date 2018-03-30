module Pod
	class Command
		class Binary < Command
			class Lint < Binary
				self.abstract_command = false
				self.summary = '对本地二进制进行 Lint'
				self.description = <<-DESC
					对本地二进制进行 Lint
	      DESC

	      def run
        	
        end
			end
		end
	end
end