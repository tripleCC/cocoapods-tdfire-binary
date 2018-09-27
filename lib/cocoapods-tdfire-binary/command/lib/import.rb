require 'cocoapods'
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
  class Command
    class Binary < Command
      class Lib < Binary
      	class Import < Lib
      		self.abstract_command = false
	        self.summary = '根据 podspec 生成伞头文件'
	        self.description = <<-DESC
						根据 podspec 生成伞头文件, 没有将根据组件名创建, 已存在直接替换
	        DESC

	        self.arguments = [
            CLAide::Argument.new('PATH', false),
        	]

	        def initialize(argv)
	        	@path = argv.shift_argument || "#{pod_name}.h"
	        	@path = Pathname.new(@path) 
	        	@spec_file = first_podspec
	          super
	        end

	        def validate!
	          super
	          help! '当前目录下没有podspec文件.' if @spec_file.nil?
	        end

	        def run
	          UI.section("Tdfire: import public header files to #{@path} ...") do
	          	pod_name = @spec_file.split('.').first
	          	header_generator = Pod::Generator::Header.new(Platform.ios)  
	          	spec = Pod::Specification.from_file(Pathname.new(@spec_file))
	          	public_header_files = spec.consumer(:ios).public_header_files
	          	public_header_files = spec.consumer(:ios).source_files if public_header_files.empty?
	          	public_header_files = Pathname.glob(public_header_files).map(&:basename).select do |pathname|
	          		pathname.extname.to_s == '.h' &&
	          		pathname.basename('.h').to_s != pod_name
	          	end

	          	UI.message "Tdfire: import public header files #{public_header_files.map(&:to_s)}"

	          	header_generator.imports = public_header_files
	          	header_generator.save_as(@path)
	          end
	        end
      	end
      end
    end
  end
end