require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
  class Specification
  	#--------------------------------------------------------------------#
  	# =>  获取自身以及子组件的属性合并值
  	#--------------------------------------------------------------------#
  	def all_value_for_attribute(name)
  		(Array(self) + Array(recursive_subspecs))
      .map { |s| s.attributes_hash[name] }
      .compact
  	end

  	def all_hash_value_for_attribute(name)
  		all_value_for_attribute(name).reduce({}, :merge)
  	end

  	def all_array_value_for_attribute(name)
  		all_value_for_attribute(name).flatten
  	end

  	def store_array_value_with_attribute_and_reference_spec(name, spec)
  		temp = spec.all_array_value_for_attribute(name)
  		temp += attributes_hash[name] unless attributes_hash[name].nil?
  		store_attribute(name, temp) unless temp.empty?  
  	end

  	def store_hash_value_with_attribute_and_reference_spec(name, spec, &select)
  		temp = spec.all_hash_value_for_attribute(name)
  		temp.merge!(attributes_hash[name]) unless attributes_hash[name].nil?
			temp.select! { |k, v| yield k if block_given? }
  		store_attribute(name, temp) unless temp.empty?  
  	end
  	#--------------------------------------------------------------------#
  end
end

module Tdfire
	class BinarySpecificationRefactor
		attr_accessor :target_spec

		def initialize(target_spec)
			@target_spec = target_spec
		end

		#--------------------------------------------------------------------#
		# 生成default subspec TdfireBinary ，并将源码依赖时的配置转移到此 subspec 上
		def configure_binary_default_subspec_with_reference_spec(spec)
			default_subspec = "TdfireBinary"
			target_spec.subspec default_subspec do |ss|
				subspec_refactor = BinarySpecificationRefactor.new(ss)
				subspec_refactor.configure_binary_with_reference_spec(spec)
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
		def configure_binary_with_reference_spec(spec)
			# 组件 frameworks 的依赖
			target_spec.vendored_frameworks = "#{target_spec.root.name}.framework"
			# target_spec.source_files = "#{target_spec.root.name}.framework/Headers/*"
			# target_spec.public_header_files = "#{target_spec.root.name}.framework/Headers/*"

			# 保留对 frameworks lib 的依赖
      %w[frameworks libraries weak_frameworks].each do |name|
        target_spec.store_array_value_with_attribute_and_reference_spec(name, spec)
      end

      # 保留对其他组件的依赖
      target_spec.store_hash_value_with_attribute_and_reference_spec('dependencies', spec) do |name|
				# 去除对自身子组件的依赖
				name.split('/').first != target_spec.root.name
			end

			Pod::UI.message "Tdfire: dependencies for #{target_spec.name}: #{target_spec.dependencies.map(&:name).join(', ')}"
		end

		#--------------------------------------------------------------------#		
		# spec 是源码依赖时的配置
		def set_preserve_paths_with_reference_spec(spec)
			# 源码、资源文件
      source_files = spec.all_array_value_for_attribute('source_files')
      resources = spec.all_array_value_for_attribute('resources')
      resource_bundles = spec.all_hash_value_for_attribute('resource_bundles')
      source_preserve_paths = source_files + resources + resource_bundles.values.flatten

      # 二进制文件
      framework_preserve_paths = [framework_name]
      preserve_paths = source_preserve_paths + framework_preserve_paths

      # 保留原有的 preserve_paths
      preserve_paths += target_spec.attributes_hash['preserve_paths'] unless target_spec.attributes_hash['preserve_paths'].nil?
      target_spec.preserve_paths = preserve_paths.uniq

      Pod::UI.message "Tdfire: preserve paths for #{target_spec.name}: #{preserve_paths.join(', ')}"
		end

		#--------------------------------------------------------------------#

		def set_use_static_framework
			target_spec.static_framework = true
		end

		#--------------------------------------------------------------------#
		def set_framework_download_script
			download_url = BinaryUrlManager.pull_url_for_pod_version(target_spec.root.name, target_spec.version)

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

		def framework_name
      "#{target_spec.root.name}.framework"
    end
	end
end