require 'cocoapods-tdfire-binary/binary_state_store'
require 'cocoapods-tdfire-binary/binary_specification_refactor'
require 'colored2'

module Pod
  class Specification
    include Tdfire

    def tdfire_refactor
      @refactor ||= BinarySpecificationRefactor.new(self)
    end

    module DSL

      public

      # 此次操作，Podfile 是否使用了 use_frameworks!
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

          # 在设置了 use_frameworks! 的情况下才会生效
          tdfire_refactor.set_use_static_framework
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

          # name 一定要有，否则 subspec dependecy 会出现 split nil 错误
          @tdfire_reference_spec = Specification.new(nil, 'TdfireSpecification')
          configurator.call @tdfire_reference_spec

          # 如果存在 subspec，则生成 default subpsec ，并将所有的 subspec 配置转移到此 subspec 中
          # 已存在的 subspec 依赖此 subspec
          unless @tdfire_reference_spec.subspecs.empty?
            tdfire_refactor.configure_binary_default_subspec_with_reference_spec( @tdfire_reference_spec)
          else
            tdfire_refactor.configure_binary_with_reference_spec( @tdfire_reference_spec)
          end
        end
      end

      # 配置二进制文件下载、cache 住解压好的 framework
      def tdfire_set_binary_download_configurations(download_url = nil)
        tdfire_refactor.set_preserve_paths_with_reference_spec(tdfire_reference_spec)

        # 没有发布的pod，没有二进制版本，不进行下载配置
        return if !Tdfire::BinaryStateStore.force_use_binary? && Tdfire::BinaryStateStore.unpublished_pods.include?(root.name)

        raise Pod::Informative, "You must invoke the method after setting name and version" if root.name.nil? || version.nil?

        tdfire_refactor.set_framework_download_script
      end
    end

    private 

    def tdfire_reference_spec
      @tdfire_reference_spec || self        
    end

    def tdfire_use_source?
      (!Tdfire::BinaryStateStore.force_use_binary? && 
      (!Tdfire::BinaryStateStore.use_binary? || Tdfire::BinaryStateStore.real_use_source_pods.include?(root.name))) ||
      Tdfire::BinaryStateStore.force_use_source?
    end
  end
end