require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
	class Command
		class Binary < Command
			class Lib < Binary
				class Create < Lib
					self.abstract_command = false
					self.summary = '创建二进制模版库'
					self.description = <<-DESC
						创建二进制模版库
		      DESC

		      self.arguments = [
            CLAide::Argument.new('NAME', true),
        	]

        	def initialize(argv)
        		@name = argv.shift_argument
        		super
        	end

        	def validate!
        		super
        		help! "必须提供有效组件名称" if @name.nil?
        	end

        	def run
        		argvs = [
        			"--template-url=#{Tdfire::BinaryUrlManager.template_lib_url}",
        			@name
        		]

        		create = Pod::Command::Lib::Create.new(CLAide::ARGV.new(argvs))
            create.validate!
            create.run
        	end
		    end
		  end
		end
	end
end