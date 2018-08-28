require 'cocoapods-tdfire-binary/binary_state_store'


module Pod
  class Podfile
    module DSL

      # 使用源码依赖的pod
      def tdfire_use_source_pods(pods)
        Pod::UI.puts "Tdfire: set use source pods: #{Array(pods).join(', ')}"
        Pod::Tdfire::BinaryStateStore.use_source_pods = Array(pods)
      end

      # 使用二进制依赖
      def tdfire_use_binary!
        Pod::Tdfire::BinaryStateStore.set_use_binary
      end  

      def tdfire_third_party_use_binary!
        Pod::Tdfire::BinaryStateStore.set_third_party_use_binary
      end

      # 因为暂时无法将全部组件二进制化，tdfire_use_binary! 默认全部进行二进制依赖不利于渐进测试
      # 所以添加 tdfire_use_source! 默认全部进行源码依赖，开放指定二进制依赖组件接口
      # 
      # 使用二进制依赖的pod
      # 与 tdfire_use_binary 互斥
      # def tdfire_use_binary_pods(pods)
      #   Pod::UI.puts "Tdfire: set use binary pods: #{Array(pods).join(', ')}"
      #   Pod::Tdfire::BinaryStateStore.use_binary_pods = Array(pods)
      # end
      #
      # def tdfire_use_source!
      # end

      # 强制使用二进制依赖，忽略未发布和依赖源码设置
      # def tdfire_force_use_binary!
      #   Pod::Tdfire::BinaryStateStore.set_force_use_binary
      # end

      # 外源组件依赖
      def tdfire_external_pods(pods, *rest)
      	argvs = rest.last || {}
        if !argvs.kind_of?(Hash)
          info =  <<-EOF
            输入参数错误.

            Example:
              tdfire_external_pods ['TDFCore'], source:'git', group:'ios', branch:'develop'
              tdfire_external_pods 'TDFCore', source:'git', group:'ios', branch:'develop'
              tdfire_external_pods ['TDFCore'], group:'cocoapods' 
              ...

            默认值：
              source:path
              group:ios
              branch:develop

            所有值:
              source -> git path
              group -> 任意
              branch -> 任意

            格式可以和pod语法一致
          EOF
          raise Pod::Informative, info
        end

        UI.puts argvs
        source = argvs[:source] || 'git'
        group = argvs[:group] || 'ios'
        branch = argvs[:branch] || 'develop'

        case source
          when 'path'
          Array(pods).each do |name|
              if File.exist?("../../#{name}/#{name}.podspec")
                pod name, :path => "../../#{name}"
              else
                pod name, :path => "../#{name}"
              end
          end
          when 'git'
          Array(pods).each do |name|
              pod name, :git => "git@git.2dfire-inc.com:#{group}/#{name}.git", :branch => "#{branch}"
          end
          else
        end
      end
    end
	end
end
