require 'cocoapods-tdfire-binary/binary_state_store'
require 'colored2'

module Pod
  class Specification
    module DSL

      public

      def tdfire_use_frameworks?
        Tdfire::BinaryStateStore.use_frameworks
      end

      # 源码依赖配置
      def tdfire_source(configurator)
        if tdfire_use_source?
          if !Tdfire::BinaryStateStore.printed_pods.include?(root.name)
            UI.message "Source".magenta.bold + " dependecy for " + "#{root.name} #{version}".green.bold
            Tdfire::BinaryStateStore.printed_pods << root.name
          end

          configurator.call self
        end
      end

      # 二进制依赖配置
      def tdfire_binary(configurator, &block)
        if !tdfire_use_source?
          if !Tdfire::BinaryStateStore.printed_pods.include?(root.name)
            UI.message "Binary".cyan.bold + " dependecy for " + "#{root.name} #{version}".green.bold 
            Tdfire::BinaryStateStore.printed_pods << root.name
          end

          yield self if block_given?

          @tdfire_source_spec = Spec.new
          configurator.call @tdfire_source_spec
          tdfire_set_binary_configuration(@tdfire_source_spec)
        end
      end

      # 配置二进制文件下载、cache 住解压好的 framework
      def tdfire_set_binary_download_configurations(download_url = nil)
        tdfire_set_use_static_framework
        tdfire_set_preserve_paths

        # 没有发布的pod，没有二进制版本，不进行下载配置
        return if !Tdfire::BinaryStateStore.force_use_binary? && Tdfire::BinaryStateStore.unpublished_pods.include?(root.name)

        raise Pod::Informative, "You must invoke the method after setting name and version" if root.name.nil? || version.nil?

        tdfire_set_framework_download_script(download_url || tdfire_framework_url_for_pod_version(root.name, version))
      end
    end

    public

    # 设置二进制依赖配置
    def tdfire_set_binary_configuration(spec)
      # 组件frameworks的依赖
      store_attribute('vendored_frameworks', "#{root.name}.framework")
      store_attribute('source_files', "#{root.name}.framework/Headers/*")
      store_attribute('public_header_files', "#{root.name}.framework/Headers/*")

      # 保留对frameworks lib 的依赖
      %w[frameworks libraries weak_frameworks].each do |attribute|
        tdfire_store_binary_array_attribute(spec, attribute)
      end

      # 保留对其他组件的依赖
      tdfire_store_binary_hash_attribute(spec, 'dependencies')
    end

    def tdfire_set_binary_subspecs(spec)
      # spec.subspecs.each do |s|
        # subspec(s.name.split('/').last) do |ss|
        #   ss.tdfire_set_binary_configuration(spec)

        #   puts
        # end
        # if valide_subspec.nil?
        #   valide_subspec = s
        #   subspec(s.name) do |ss|
        #     ss.set_binary_configuration()
        #   end
        # else
        #   subspec(s.name) do |ss|
        #     ss.dependecy valide_subspec.name
        #   end
        # end
      # end
    end

    private 

    # 开启静态framework
    def tdfire_set_use_static_framework
      store_attribute('static_framework', true)
    end

    # 同时保留源码资源，二进制文件
    def tdfire_set_preserve_paths
      # 源码、资源文件
      source_files = tdfire_binary_array_attribute(tdfire_source_spec, 'source_files')
      resources = tdfire_binary_array_attribute(tdfire_source_spec, 'resources')
      resource_bundles = tdfire_binary_hash_attribute(tdfire_source_spec, 'resource_bundles')

      source_preserve_paths = source_files + resources + resource_bundles.values.flatten

      # 二进制文件
      framework_preserve_paths = [tdfire_framework_name]

      preserve_paths = source_preserve_paths + framework_preserve_paths
      preserve_paths += tdfire_ios_consumer.preserve_paths unless tdfire_ios_consumer.preserve_paths.nil?

      UI.message "Tdfire: preserve paths: #{preserve_paths.join(', ')}"

      store_attribute('preserve_paths', preserve_paths)
    end

    # 设置二进制下载脚本
    def tdfire_set_framework_download_script(download_url)
      download_script = <<~EOF
        #!/bin/sh

        if [[ -d #{tdfire_framework_name} ]]; then
          echo "Tdfire: #{tdfire_framework_name} is not empty"
          exit 0
        fi

        if [[ ! -d tdfire_download_temp ]]; then
          mkdir tdfire_download_temp
        fi

        cd tdfire_download_temp

        curl --fail -O -J -v #{download_url}

        if [[ -f #{tdfire_framework_name}.zip ]]; then
          echo "Tdfire: copying #{tdfire_framework_name} ..."

          unzip #{tdfire_framework_name}.zip
          cp -fr #{tdfire_framework_relative_path} ../
        fi

        cd ..
        rm -fr tdfire_download_temp

        echo "pod cache path for #{root.name}: $(pwd)"
      EOF

      eval_download_script = %Q[echo '#{download_script}' > download.sh && sh download.sh && rm download.sh]
      eval_download_script += " && " << prepare_command unless prepare_command.nil?

      store_attribute('prepare_command', eval_download_script)
    end

    # 二进制文件url
    def tdfire_framework_url_for_pod_version (pod, version)
      "http://iosframeworkserver-shopkeeperclient.cloudapps.2dfire.com/getframework/PRODUCTION/#{pod}/#{version}"
    end

    # 二进制名称
    def tdfire_framework_name
      "#{root.name}.framework"
    end

    # 二进制相对路径
    def tdfire_framework_relative_path
      "./#{tdfire_framework_name}"
    end

    def tdfire_store_binary_array_attribute(spec, attribute)
      temp = tdfire_binary_array_attribute(spec, attribute)
      temp += attributes_hash[attribute] unless attributes_hash[attribute].nil?
      store_attribute(attribute, temp) unless temp.empty?  
    end

    def tdfire_store_binary_hash_attribute(spec, attribute)
      temp = tdfire_binary_hash_attribute(spec, attribute)
      puts "temp #{temp}"
      puts "#{attribute} #{attributes_hash[attribute]}"
      temp.merge!(attributes_hash[attribute]) unless attributes_hash[attribute].nil?
      store_attribute(attribute, temp) unless temp.empty?  
    end

    def tdfire_binary_array_attribute(spec, attribute)
      (Array(spec) + Array(spec.subspecs))
      .map { |s| s.attributes_hash[attribute] }
      .compact
      .flatten
    end

    def tdfire_binary_hash_attribute(spec, attribute)
      (Array(spec) + Array(spec.subspecs))
      .map { |s| s.attributes_hash[attribute] }
      .compact
      .reduce({}, :merge)
    end
    
    def tdfire_source_spec
      @tdfire_source_spec || self        
    end

    def tdfire_ios_consumer
      consumer(Platform.ios)
    end

    def tdfire_use_source?
      (!Tdfire::BinaryStateStore.force_use_binary? && 
      (!Tdfire::BinaryStateStore.use_binary? || Tdfire::BinaryStateStore.real_use_source_pods.include?(root.name))) ||
      Tdfire::BinaryStateStore.force_use_source?
    end
  end
end