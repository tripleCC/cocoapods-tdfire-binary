require 'cocoapods-tdfire-binary/binary_state_store'
require 'cocoapods-tdfire-binary/binary_specification_refactor'
require 'colored2'

module Pod
  class Specification
    def tdfire_refactor
      @refactor ||= Pod::Tdfire::BinarySpecificationRefactor.new(self)
    end

    module DSL

      public

      # 此次操作，Podfile 是否使用了 use_frameworks!
      def tdfire_use_frameworks?
        Tdfire::BinaryStateStore.use_frameworks
      end

      # 源码依赖配置
      def tdfire_source(configurator)
        tdfire_set_binary_strategy_flag

        if tdfire_use_source?
          if !Pod::Tdfire::BinaryStateStore.printed_pods.include?(root.name)
            UI.message "Source".magenta.bold + " dependecy for " + "#{root.name} #{version}".green.bold
            Pod::Tdfire::BinaryStateStore.printed_pods << root.name
          end

          configurator.call self

          tdfire_refactor.configure_source
        end
      end

      # 二进制依赖配置
      def tdfire_binary(configurator, &block)
        tdfire_set_binary_strategy_flag

        if !tdfire_use_source?
          if !Pod::Tdfire::BinaryStateStore.printed_pods.include?(root.name)
            UI.message "Binary".cyan.bold + " dependecy for " + "#{root.name} #{version}".green.bold
            Pod::Tdfire::BinaryStateStore.printed_pods << root.name
          end

          # name 一定要有，否则 subspec dependecy 会出现 split nil 错误
          @tdfire_reference_spec = Specification.new(nil, 'TdfireSpecification')
          configurator.call @tdfire_reference_spec

          # 如果存在 subspec，则生成 default subpsec ，并将所有的 subspec 配置转移到此 subspec 中
          # 已存在的 subspec 依赖此 subspec
          unless @tdfire_reference_spec.recursive_subspecs.empty?
            tdfire_refactor.configure_binary_default_subspec(@tdfire_reference_spec)
          else
            tdfire_refactor.configure_binary(@tdfire_reference_spec)
          end

          yield self if block_given?
        end
      end


      # 配置二进制文件下载、cache 住解压好的 framework
      def tdfire_set_binary_download_configurations
        tdfire_set_binary_strategy_flag

        tdfire_refactor.set_preserve_paths(tdfire_reference_spec)

        # 没有发布的pod，没有二进制版本，不进行下载配置
        return if tdfire_should_skip_download?

        raise Pod::Informative, "You must invoke the method after setting name and version" if root.name.nil? || version.nil?

        tdfire_refactor.set_framework_download_script
      end
    end

    def tdfire_use_source?
      ((((!Pod::Tdfire::BinaryStateStore.force_use_binary? &&
          (!Pod::Tdfire::BinaryStateStore.use_binary? || Pod::Tdfire::BinaryStateStore.real_use_source_pods.include?(root.name)) && 
          (!(Pod::Tdfire::BinaryStateStore.third_party_use_binary? && tdfire_third_party?) || Pod::Tdfire::BinaryStateStore.real_use_source_pods.include?(root.name))) ||
          Pod::Tdfire::BinaryStateStore.force_use_source?) &&
          (Pod::Tdfire::BinaryStateStore.lib_lint_binary_pod != root.name)) || 
          !tdfire_had_set_binary_strategy)
    end

    private 
    def tdfire_third_party?
      if source 
        source[:git]&.include?('cocoapods-repos')
      else 
        false
      end
    end

    # 没有配置二进制策略的，使用源码依赖
    def tdfire_had_set_binary_strategy
      @tdfire_binary_strategy_flag || false
    end

    def tdfire_set_binary_strategy_flag
      @tdfire_binary_strategy_flag = true
    end

    def tdfire_reference_spec
      @tdfire_reference_spec || self        
    end

    def tdfire_should_skip_download?
      (!Pod::Tdfire::BinaryStateStore.force_use_binary? && Pod::Tdfire::BinaryStateStore.unpublished_pods.include?(root.name)) ||
          (Pod::Tdfire::BinaryStateStore.lib_lint_binary_pod == root.name)
    end
  end
end