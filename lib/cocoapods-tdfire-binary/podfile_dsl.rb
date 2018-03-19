require 'cocoapods-tdfire-binary/binary_state_store'


module Pod
  class Podfile
    module DSL
      # 使用源码依赖的pod
      def tdfire_use_source_pods(pods)
      	old_pods = Tdfire::BinaryStateStore.use_source_pods
      	UI.puts "Tdfire: the use source pods: #{old_pods.join(',')} will be overrided by new pods: #{pods.join(',')}".cyan if (!old_pods.empty? && old_pods != pods )

      	Tdfire::BinaryStateStore.use_source_pods = pods
      end

      # 强制使用二进制依赖
      def tdfire_force_use_binary!
        Tdfire::BinaryStateStore.set_force_use_binary
      end

      # 使用二进制依赖
      def tdfire_use_binary!
        Tdfire::BinaryStateStore.set_use_binary
      end

      # 外源组件依赖
      def tdfire_external_pods(pods, *rest)
      	argvs = rest.last || {}
        if !argvs.kind_of?(Hash)
          info =  <<-EOF
输入参数错误.

Example:
  tdfire_external_pods ['TDFCore'] source:'git' group:'ios' branch:'develop'
  tdfire_external_pods 'TDFCore' source:'git' group:'ios' branch:'develop'
  tdfire_external_pods ['TDFCore'] group:'cocoapods' 
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

      	# 除了依赖私有源正式版本的组件，其余组件一律进行源码依赖
        Tdfire::BinaryStateStore.use_source_pods = Array(pods) + Tdfire::BinaryStateStore.use_source_pods
      end
    end
	end
end
