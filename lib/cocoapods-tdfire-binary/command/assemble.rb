require 'cocoapods-tdfire-binary/command/package'
require 'cocoapods-tdfire-binary/command/lint'
require 'cocoapods-tdfire-binary/command/publish'
require 'cocoapods-tdfire-binary/command/push'
require 'cocoapods-tdfire-binary/binary_state_store'

module Pod
  class Command
    class Binary < Command
      class Assemble < Binary
        self.abstract_command = false
        self.summary = '执行二进制组件发布操作集合'
        self.description = <<-DESC
          执行二进制组件发布操作集合，依次为 package、lint、push、publish
        DESC

        def validate!
          super
          help! "当前目录下找不到有效的 podspec 文件" if first_podspec.nil?
        end

        def run
          run_command Package, ['--clean']
          run_command Lint
          run_command Push
          run_command Publish
        end

        def run_command(command_class, argv = [])
          lint = command_class::new(CLAide::ARGV.new(argv))
          lint.validate!
          lint.run
          Pod::Tdfire::BinaryStateStore.printed_pods.clear
        end
      end
    end
  end
end