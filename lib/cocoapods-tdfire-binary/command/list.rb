
require 'json'
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
  class Command
    class Binary < Command
      class List < Binary

        self.abstract_command = false
        self.summary = '查看所有二进制版本信息'
        self.description = <<-DESC
					查看所有二进制版本信息
        DESC

        def initialize(argv)
          super
        end

        def validate!
          super
        end

        def run
          result = Pod::Tdfire::BinaryUrlManager.list_binary
          begin
            pods = JSON.parse(result) unless result.nil?
            pods ||= []
            pods.sort.each do |pod, versions|
              UI.puts "  #{pod + " " + versions.last}\n"
            end
            UI.puts "\n#{pods.keys.count} pods were found"
          rescue JSON::ParserError => err
            UI.puts "查看二进制信息失败, 服务器返回 #{result}".red
          end

        end
      end
    end
  end
end