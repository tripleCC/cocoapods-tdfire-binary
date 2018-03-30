require 'colored2'
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
	class Command
		class Binary < Command
			class Package < Binary 
        self.abstract_command = false
				self.summary = '二进制打包'
				self.description = <<-DESC
					将源码打包成二进制，并压缩成 zip 包
	      DESC

	      def self.options
          [
            ['--clean', '执行成功后，删除 zip 文件外的所有生成文件'],
          ].concat(super)
        end

	      def initialize(argv)
	      	@clean = argv.flag?('clean')
	      	@spec_file = first_podspec
	      	super
	      end

        def validate!
          super
          help! '当前目录下没有podspec文件.' if @spec_file.nil?
        end

        def run
        	spec = Specification.from_file(@spec_file)
        	package(spec)
        	zip(spec)
        end

        private

        def package(spec)
        	UI.section("Tdfire: package #{spec.name} ...") do
	        	system "pod package #{spec.name}.podspec --exclude-deps --force --no-mangle --spec-sources=#{Tdfire::BinaryUrlManager.private_cocoapods_url}"
	        end
        end

        def zip(spec)
        	framework_path = "#{spec.name}-#{spec.version}/ios/#{spec.name}.framework"

        	raise Informative, "没有需要压缩的 framework 文件：#{framework_path}" unless File.exist?(framework_path)

        	output_name = "#{spec.name}.framework.zip"
        	UI.section("Tdfire: zip #{framework_path} ...") do
						system "zip #{output_name} #{framework_path}"
					end

					Pod::UI::puts "Tdfire: save framework zip file to #{Dir.pwd}/#{output_name}".green

					system "rm -fr #{spec.name}-#{@spec.version}" if @clean
        end

			end
		end
	end
end