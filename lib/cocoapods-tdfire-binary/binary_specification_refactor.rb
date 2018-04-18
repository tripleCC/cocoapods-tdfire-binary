require 'cocoapods-tdfire-binary/binary_url_manager'
require 'cocoapods-tdfire-binary/binary_state_store'

module Pod
  class Specification
  	#--------------------------------------------------------------------#
  	# =>  获取自身以及子组件的属性合并值
  	#--------------------------------------------------------------------#
    # def all_value_for_attribute(name)
  		# (Array(self) + Array(recursive_subspecs))
    #   .map { |s| s.attributes_hash[name] }
    #   .compact
    # end
    #
    # def all_hash_value_for_attribute(name)
  		# all_value_for_attribute(name).reduce({}, :merge)
    # end
    #
    # def all_array_value_for_attribute(name)
  		# all_value_for_attribute(name).flatten
    # end
    #
    # def store_array_value_with_attribute_and_reference_spec(name, spec)
  		# temp = spec.all_array_value_for_attribute(name)
  		# temp += attributes_hash[name] unless attributes_hash[name].nil?
  		# store_attribute(name, temp) unless temp.empty?
    # end
    #
    # def store_hash_value_with_attribute_and_reference_spec(name, spec, &select)
  		# temp = spec.all_hash_value_for_attribute(name)
  		# temp.merge!(attributes_hash[name]) unless attributes_hash[name].nil?
			# temp.select! { |k, v| yield k } if block_given?
    #   store_attribute(name, temp) unless temp.empty?
    # end

    def tdfire_recursive_value(name, platform = :ios)
      subspec_consumers = recursive_subspecs
                              .select { |s| s.supported_on_platform?(platform) }
                              .map { |s| s.consumer(platform) }
                              .uniq
      value = (Array(consumer(platform)) + subspec_consumers).map { |c| c.send(name) }.flatten.uniq
      value
    end
  	#--------------------------------------------------------------------#
  end
end

module Pod
	module Tdfire
		class BinarySpecificationRefactor
			attr_accessor :target_spec

			def initialize(target_spec)
				@target_spec = target_spec
			end

      def configure_source
        # 在设置了 use_frameworks! 的情况下才会生效
        set_use_static_framework

        # cocoapods-package 打包时，只让 iOS 平台生效
        set_platform_limitation(target_spec) if Pod::Tdfire::BinaryStateStore.limit_platform
      end

			#--------------------------------------------------------------------#
			# 生成default subspec TdfireBinary ，并将源码依赖时的配置转移到此 subspec 上
			def configure_binary_default_subspec(spec)
        # 限制二进制只支持 iOS 平台 （这里是 parent spec）
        set_platform_limitation(spec)

				default_subspec = "TdfireBinary"
				target_spec.subspec default_subspec do |ss|
					subspec_refactor = BinarySpecificationRefactor.new(ss)
					subspec_refactor.configure_binary(spec)
        end

				# 创建源码依赖时的 subspec，并且设置所有的 subspec 依赖 default_subspec
				spec.subspecs.each do |s|
					target_spec.subspec s.base_name do |ss|
						ss.dependency "#{target_spec.root.name}/#{default_subspec}"
					end
				end

				target_spec.default_subspec = default_subspec
				target_spec.default_subspec = default_subspec

				Pod::UI.message "Tdfire: subspecs for #{target_spec.name}: #{target_spec.subspecs.map(&:name).join(', ')}"
			end

			#--------------------------------------------------------------------#
			# spec 是二进制依赖时的配置
			def configure_binary(spec)
        # 限制二进制只支持 iOS 平台 （这里是 spec 或者 subpsec）
        set_platform_limitation(spec)

				# 组件 frameworks 的依赖
				target_spec.vendored_frameworks = "#{target_spec.root.name}.framework"
        # 如果不加这一句，会提示找不到 bundle。测试时需要 shift + cmd + k 清除 production
        #
        # static framework 不像 dynamic framework ，后者在生成 production 后，会有一个专门的 Frameworks 文件夹，其内部的结构和打包前是一致的， bundle 也会在 .framework 文件中
        # 而 static framework 的可执行文件部分，会被合并到 App 的可执行文件中， bundle 按逻辑会放到 main bundle 中，
        # 但是 CocoaPods 并不会帮 vendored_frameworks 中的 static framework  做 bundle 的拷贝工作，
        # 所以这里需要暴露 static framework 中的 bundle ，明确让 CocoaPods 拷贝 bundle 到 main bundle，
        # 可以查看 高德地图 和 友盟等 framework ，都已这种方式处理
        #
        target_spec.resources = ["#{target_spec.root.name}.framework/Resources/*.bundle", "#{target_spec.root.name}.framework/Versions/A/Resources/*.bundle"]
				# target_spec.source_files = ["#{target_spec.root.name}.framework/Headers/*", "#{target_spec.root.name}.framework/Versions/A/Headers/*"]
				# target_spec.public_header_files = ["#{target_spec.root.name}.framework/Headers/*", "#{target_spec.root.name}.framework/Versions/A/Headers/*"]

        available_platforms(spec).each do |platform|
          Pod::UI.section("Tdfire: copying configuration for platform #{platform}") do
            target_platform = target_spec.send(platform.to_sym)

            # 保留对 frameworks lib 的依赖
            %w[frameworks libraries weak_frameworks].each do |name|
              value = spec.tdfire_recursive_value(name, platform )
              target_platform.send("#{name}=", value) unless value.empty?

              Pod::UI.message "Tdfire: #{name} for #{platform}: #{target_spec.tdfire_recursive_value(name, platform)}"
            end

            # 保留对其他组件的依赖
            dependencies = spec.tdfire_recursive_value('dependencies', platform)

            # 去除对自身子组件的依赖
            dependencies
                .select { |d| d.root_name != target_spec.root.name }
                .each { |d| target_platform.dependency(d.name, d.requirement.to_s) }

            Pod::UI.message "Tdfire: dependencies for #{platform}: #{target_spec.tdfire_recursive_value('dependencies', platform).map(&:name).join(', ')}"
          end
        end
      end

      def set_platform_limitation(spec)
        target_spec.platform = :ios, deployment_target(spec, :ios)
      end
			#--------------------------------------------------------------------#
			# spec 是源码依赖时的配置
			def set_preserve_paths(spec)
        available_platforms(spec).each do |platform|
          Pod::UI.section("Tdfire: set preserve paths for platform #{platform}") do
            # 源码、资源文件
            #
            source_files = spec.tdfire_recursive_value('source_files', platform)
            resources = spec.tdfire_recursive_value('resources', platform)
            resource_bundles = spec.tdfire_recursive_value('resource_bundles', platform)

            source_preserve_paths = source_files + resources + resource_bundles.map(&:values).flatten

            # 二进制文件
            framework_preserve_paths = [framework_name]
            preserve_paths = source_preserve_paths + framework_preserve_paths

            # 保留原有的 preserve_paths
            target_preserve_paths = target_spec.tdfire_recursive_value('preserve_paths', platform)
            preserve_paths += target_preserve_paths unless target_preserve_paths.empty?

            target_platform = target_spec.send(platform.to_sym)
            target_platform.preserve_paths = preserve_paths.uniq

            Pod::UI.message "Tdfire: preserve paths for #{platform}: #{preserve_paths.join(', ')}"
          end
        end
			end

			#--------------------------------------------------------------------#

			def set_use_static_framework
        # 1.4.0 版本生效
        # 使用 use_frameworks! 后，生成静态 Framework
        #
				target_spec.static_framework = true if target_spec.respond_to?('static_framework')
			end

			#--------------------------------------------------------------------#
			def set_framework_download_script
				download_url = Pod::Tdfire::BinaryUrlManager.pull_url_for_pod_version(target_spec.root.name, target_spec.version)

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
          cp -fa #{framework_name} ../
        fi

        cd ..
        rm -fr tdfire_download_temp

        echo "pod cache path for #{target_spec.root.name}: $(pwd)"
				EOF

				combined_download_script = %Q[echo '#{download_script}' > download.sh && sh download.sh && rm download.sh]
				combined_download_script += " && " << target_spec.prepare_command unless target_spec.prepare_command.nil?

				target_spec.prepare_command = combined_download_script
			end

			#--------------------------------------------------------------------#
			private

      def deployment_target(spec, platform = :ios)
        target_spec.deployment_target(platform) || spec.deployment_target(platform)
      end

      def available_platforms(spec)
        # 平台信息没设置，表示支持所有平台
        # 所以二进制默认支持所有平台，或者和源码时支持平台一致(平台设置在源码配置lambda外)
        # 支持多平台用 deployment_target，单平台用 platform
        #
        target_spec.available_platforms || spec.available_platforms || [:ios]
      end

			def framework_name
				"#{target_spec.root.name}.framework"
			end
		end
	end
end
