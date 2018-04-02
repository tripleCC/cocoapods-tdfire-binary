require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
	class Command
		class Binary < Command
			class Pull < Binary
				self.abstract_command = false
				self.summary = '下载二进制 zip 包'
				self.description = <<-DESC
					通过 NAME 和 VERSION ，下载二进制 zip 包
	      DESC

	      self.arguments = [
          CLAide::Argument.new('NAME', true),
          CLAide::Argument.new('VERSION', true)
        ]

        def initialize(argv)
        	@name = argv.shift_argument
        	@version = argv.shift_argument
        	super
        end

        def validate!
          super
          help! "必须提供有效组件名" if @name.nil?
          help! "必须提供有效版本号" if @version.nil?
        end

        def run
					UI.section("Tdfire: start pulling framework zip file ...") do
						UI.puts "Tdfire: get argvs: name -> #{@name}, version -> #{@version}"
        	  Tdfire::BinaryUrlManager.get_pull_url_for_pod_version(@name, @version)
					end
        end
			end
		end
	end
end