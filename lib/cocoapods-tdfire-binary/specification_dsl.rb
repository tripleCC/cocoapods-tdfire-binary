require 'cocoapods-tdfire-binary/binary_state_store'
require 'colored2'

module Pod
  class Specification
    module DSL

      private 

      def use_source?
        (!Tdfire::BinaryStateStore.force_use_binary? && 
        (!Tdfire::BinaryStateStore.use_binary? || Tdfire::BinaryStateStore.real_use_source_pods.include?(root.name))) ||
        Tdfire::BinaryStateStore.force_use_source?
      end

    	public

      def tdfire_use_frameworks?
        Tdfire::BinaryStateStore.use_frameworks
      end

    	# 源码依赖配置
      def tdfire_source(configurator)
        if use_source?
          if !Tdfire::BinaryStateStore.printed_pods.include?(root.name)
          	UI.message "Source".magenta.bold + " dependecy for " + "#{root.name} #{version}".green.bold
            Tdfire::BinaryStateStore.printed_pods << root.name
          end

          configurator.call self
        end
      end

      # 二进制依赖配置
      def tdfire_binary(configurator, &block)
        if !use_source?
          if !Tdfire::BinaryStateStore.printed_pods.include?(root.name)
          	UI.message "Binary".cyan.bold + " dependecy for " + "#{root.name} #{version}".green.bold 
            Tdfire::BinaryStateStore.printed_pods << root.name
          end

          yield self if block_given?
        end
      end

      # 配置二进制文件下载、cache 住解压好的 framework
      def tdfire_set_binary_download_configurations_at_last(download_url = nil)
        set_use_static_framework
        set_framework_preserve_paths

        # 没有发布的pod，没有二进制版本，不进行下载配置
        return if !Tdfire::BinaryStateStore.force_use_binary? && Tdfire::BinaryStateStore.unpublished_pods.include?(root.name)

        raise Pod::Informative, "You must invoke the method after setting name and version" if root.name.nil? || version.nil?

        set_framework_download_script(download_url || framework_url_for_pod_version(root.name, version))
      end

      private

      def set_use_static_framework
        store_attribute('static_framework', true)
      end

      # 同时保留源码资源，二进制文件
      def set_framework_preserve_paths
        # 源码依赖下，保留二进制文件
        framework_preserve_paths = [framework_name]
        framework_preserve_paths += consumer(Platform.ios).preserve_paths unless consumer(Platform.ios).preserve_paths.nil?

        # 二进制依赖下，保留源码文件
        source_preserve_paths = ["#{root.name}/Classes/**/*", "Classes/**/*", "*.{h,m}"] 

        # 增加 consumer(Platform.ios).source_files 规避 preserve_paths don't match any files 错误
        source_preserve_paths += consumer(Platform.ios).source_files unless consumer(Platform.ios).source_files.nil?

        # 二进制依赖下，保留资源文件
        resource_preserve_paths = ["#{root.name}/Assets/**/*", "Resources/**/*", "Assets/**/*"] 

        all_preserve_paths = framework_preserve_paths + source_preserve_paths + resource_preserve_paths

        # preserve_paths = xxx 无法不会将值设置进去，不明白其原理
        store_attribute('preserve_paths', all_preserve_paths)
      end

      def set_framework_download_script(download_url)
        download_script = <<~EOF
          #!/bin/sh

          if [[ -d #{framework_name} ]]; then
            echo "Tdfire: #{framework_name} is not empty"
            exit 0
          fi

          if [[ ! -d tdfire_download_temp ]]; then
            mkdir tdfire_download_temp
          fi

          cd tdfire_download_temp

          curl --fail -O -J -v #{download_url}

          if [[ -f #{framework_name}.zip ]]; then
            echo "Tdfire: copying #{framework_name} ..."

            unzip #{framework_name}.zip
            cp -fr #{framework_relative_path} ../
          fi

          cd ..
          rm -fr tdfire_download_temp

          echo "pod cache path for #{root.name}: $(pwd)"
        EOF

        eval_download_script = %Q[echo '#{download_script}' > download.sh && sh download.sh && rm download.sh]
        eval_download_script += " && " << prepare_command unless prepare_command.nil?

        # prepare_command = xxx 在内部执行的话，无法将值设置进hash，不明白其原理
        store_attribute('prepare_command', eval_download_script)
      end

      def framework_url_for_pod_version(pod, version)
        "http://iosframeworkserver-shopkeeperclient.cloudapps.2dfire.com/getframework/PRODUCTION/#{pod}/#{version}"
      end

      def framework_name
        "#{root.name}.framework"
      end

      def framework_relative_path
        "./#{framework_name}"
      end
    end
  end
end