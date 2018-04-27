require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
  class Command
    class Binary < Command
      class Delete < Binary

        self.abstract_command = false
        self.summary = '删除二进制版本'
        self.description = <<-DESC
					将二进制从服务器中删除
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
          help! "必须为删除组件指定名称" if @name.nil?
          help! "必须为删除组件指定版本" if @version.nil?
        end

        def run
          UI.section("Tdfire: deleting binary file #{@name} #{@version} ...") do
            Pod::Tdfire::BinaryUrlManager.delete_binary(@name, @version)
          end
        end
      end
    end
  end
end