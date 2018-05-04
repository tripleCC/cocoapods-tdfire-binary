require 'cocoapods-tdfire-binary/binary_config'

module Pod
  module Tdfire
    class InitAsker
      public

      QUESTIONS = {
          BinaryConfig::SERVER_ROOT_KEY => "输入二进制服务器地址 (比如 http://xxxxx:8080)",
          BinaryConfig::REPO_URL_KEY => "输入私有源 Git 地址 (比如 https://github.com/tripleCC/PrivateSpecRepo.git)",
          BinaryConfig::TEMPLATE_URL_KEY => "输入 pod 模版 Git 地址 (比如 https://github.com/CocoaPods/pod-template.git)"
      }

      def show_prompt
        print " > ".green
      end

      def ask_with_answer(question, pre_answer)
        print "\n#{question}\n"

        print "旧值：#{pre_answer}\n" unless pre_answer.nil?

        answer = ""
        loop do
          show_prompt
          answer = STDIN.gets.chomp

          if answer == "" && !pre_answer.nil?
            answer = pre_answer
            print answer.yellow
            print "\n"
          end

          break if answer.length > 0
        end

        answer

      end

      def wellcome_message

        print <<-EOF
          
开始设置二进制化初始信息.
所有的信息都会保存在 binary_config.yaml 文件中.
你可以在 ~/.cocoapods 目录下手动添加编辑该文件.
#{BinaryConfig.instance.binary_setting_file} 文件包含配置信息如下：

#{QUESTIONS.to_yaml}
        EOF
      end

      def done_message
        print "\n设置完成.\n"
      end
    end
  end
end
