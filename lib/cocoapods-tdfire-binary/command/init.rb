require 'cocoapods-tdfire-binary/binary_url_manager'
require 'cocoapods-tdfire-binary/init_asker'

module Pod
  class Command
    class Binary < Command
      class Init < Binary

        self.abstract_command = false
        self.summary = '初始化二进制插件'
        self.description = <<-DESC
					初始化二进制插件
        DESC

        def initialize(argv)
          @asker = Tdfire::InitAsker.new
          super
        end

        def run
          @asker.wellcome_message

          hash = binary_config.setting_hash

          Tdfire::InitAsker::QUESTIONS.each do |k, v|
            default = hash[k] unless hash.nil?
            hash[k] = @asker.ask_with_answer(v, default)
          end

          binary_config.config_with_setting(hash)

          @asker.done_message
        end
      end
    end
  end
end