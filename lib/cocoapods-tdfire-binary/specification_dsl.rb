require 'cocoapods-tdfire-binary/binary_state_store'
require 'colored'

module Pod
  class Specification
    module DSL

      private 

      def use_source?
        (!Tdfire::BinaryStateStore.force_use_binary? && 
        (!Tdfire::BinaryStateStore.use_binary? || Tdfire::BinaryStateStore.use_source_pods.include?(name))) ||
        Tdfire::BinaryStateStore.force_use_source?
      end

    	public

    	# 源码依赖配置
      def tdfire_source(&block)
        if use_source?
          if !Tdfire::BinaryStateStore.printed_pods.include?(name)
          	UI.puts "Source".magenta.bold + " dependecy for " + "#{name} #{version}".blue 
            Tdfire::BinaryStateStore.printed_pods << name
          end

          yield self if block_given?
        end
      end

      # 二进制依赖配置
      def tdfire_binary(&block)
        if !use_source?
          if !Tdfire::BinaryStateStore.printed_pods.include?(name)
          	UI.puts "Binary".cyan.bold + " dependecy for " + "#{name} #{version}".blue 
            Tdfire::BinaryStateStore.printed_pods << name
          end

          yield self if block_given?
        end
      end

      # 配置二进制文件下载、cache 住解压好的 framework
      def tdfire_set_binary_download_configurations_at_last(download_url = nil)

        # 没有发布的pod，没有二进制版本，不进行下载配置
        return if !Tdfire::BinaryStateStore.force_use_binary? && Tdfire::BinaryStateStore.unpublished_pods.include?(name)

        raise Pod::Informative, "You must invoke the method after setting name and version" if name.nil? || version.nil?

        set_framework_preserve_paths
        set_framework_download_script(download_url || framework_url_for_pod_version(name, version))
      end

      private

      def framework_url_for_pod_version(pod, version)
        "http://10.1.131.104:8080/getframework/PRODUCTION/#{pod}/#{version}"
      end

      def set_framework_preserve_paths
        framework_preserve_paths = ["#{name}.framework"]
        framework_preserve_paths += consumer(Platform.ios).preserve_paths unless consumer(Platform.ios).preserve_paths.nil?

        # 规避 preserve_paths don't match any files 错误
        source_preserve_paths = ["#{name}/**/**/*", "Classes/**/*"]

        # preserve_paths = xxx 无法不会将值设置进去，不明白其原理
        store_attribute('preserve_paths', framework_preserve_paths + source_preserve_paths)
      end

      def set_framework_download_script(download_url)
        framework_name = "#{name}.framework"
        framework_relative_path = "Carthage/Build/iOS/#{framework_name}"

        download_script = <<-EOF
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

echo "pod cache path for #{name}: $(pwd)"
        EOF

        eval_download_script = %Q[echo '#{download_script}' > download.sh && sh download.sh && rm download.sh]
        eval_download_script += " && " << prepare_command unless prepare_command.nil?

        # prepare_command = xxx 在内部执行的话，无法将值设置进hash，不明白其原理
        store_attribute('prepare_command', eval_download_script)
      end
    end
  end
end