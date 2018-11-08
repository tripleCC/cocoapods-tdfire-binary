
require 'json'
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
  class Command
    class Binary < Command
      class Search < Binary

        self.abstract_command = false
        self.summary = '查找二进制版本信息'
        self.description = <<-DESC
					查找二进制版本信息
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true)
        ]

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          help! "必须指定有效组件名" if @name.nil?
        end

        def run
          result = Pod::Tdfire::BinaryUrlManager.search_binary(@name)
          begin
            pod = JSON.parse(result) unless result.nil?
            pod ||= {'' => []}

            name = pod['name'] || @name
            versions = pod['versions'] || []

            title = "-> #{name} (#{versions.last})".green

            Pod::UI::title(title, '', 1) do
              Pod::UI::labeled('Versions', versions.join(', '))
            end
          rescue JSON::ParserError => err
            UI.puts "查看二进制信息失败, 服务器返回 #{result}".red
          end
        end
      end
    end
  end
end