require 'cocoapods-tdfire-binary/binary_state_store'


module Pod
  class Podfile
    module DSL
      # 使用源码依赖的pod
      def tdfire_use_source_pods(pods)
      	old_pods = Tdfire::BinaryStateStore.use_source_pods
      	UI.puts "Tdfire: the use source pods: #{old_pods.join(',')} will be overrided by new pods: #{pods.join(',')}".cyan unless old_pods.empty? 

      	Tdfire::BinaryStateStore.use_source_pods = pods
      end

      # 使用二进制依赖
      def tdfire_use_binary!
        Tdfire::BinaryStateStore.set_use_binary
      end

      # 外源组件依赖
      def tdfire_external_pods(pods, *rest)
      	


      	# 除了依赖私有源正式版本的组件，其余组件一律进行源码依赖
      	Tdfire::BinaryStateStore.append_use_source_pods(pods)
      end
    end
	end
end
