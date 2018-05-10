require 'fileutils'
require 'colored2'
require 'cocoapods-tdfire-binary/binary_state_store'
require 'cocoapods-tdfire-binary/source_chain_analyzer'
require 'cocoapods-tdfire-binary/specification_dsl'
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
	class Installer
		old_resolve_dependencies = instance_method(:resolve_dependencies)
		define_method(:resolve_dependencies) do 
			old_resolve_dependencies.bind(self).call()

			specs = analysis_result.specifications.uniq { |s| s.root.name }
			use_binary_specs = specs.reject(&:tdfire_use_source?)

			# 1、先找出没有二进制版本的组件 
			invalid_specs =  use_binary_specs.reject do |s|
				json_string = Pod::Tdfire::BinaryUrlManager.search_binary(s.root.name)
				pod = JSON.parse(json_string, object_class: OpenStruct)
				versions = pod.versions || []
				versions.include?(s.version.to_s)
			end

			# 2、判断有效组件的 cache 中是否有二进制，没有的话，删除组件缓存
			valid_specs = use_binary_specs - invalid_specs
			if valid_specs.any?
				cache = Downloader::Cache.new(Config.instance.cache_root + 'Pods')
				cache_descriptors = cache.cache_descriptors_per_pod

				valid_specs.each do |s|
					# 2.1、处理 Pods 
					pod_dir = Config.instance.sandbox.pod_dir(s.root.name)
					framework_file = pod_dir + "#{s.root.name}.framework"
					if pod_dir.exist? && !framework_file.exist?
						UI.message "Tdfire: 删除缺少二进制的组件 #{s.root.name}".yellow
						begin
							FileUtils.rm_rf(pod_dir)
						rescue
						end
					end

					# 2.2、处理 cache
					descriptors = cache_descriptors[s.root.name]
					next if descriptors.nil?

					descriptors = descriptors.select { |d| d[:version] == s.version}
					descriptors.each do |d|

						# pod cache 文件名由文件内容的 sha1 组成，由于生成时使用的是 podspec，获取时使用的是 podspec.json 
						# 导致生成的文件名不一致
						# Downloader::Request slug
						slug = d[:slug].dirname + "#{s.version}-#{s.checksum[0, 5]}"
						framework_file = slug + "#{s.root.name}.framework"
						unless (framework_file.exist?)
							UI.message "Tdfire: 删除缺少二进制的Cache #{s.root.name}".magenta
							begin
								FileUtils.rm(descriptor[:spec_file])
								FileUtils.rm_rf(descriptor[:slug])
							rescue
							end
						end
					end
				end
			end
			
			# 3、抛出二进制不存在异常
			if invalid_specs.any?
				specs_message = invalid_specs.map do |s|
					"#{s.root.name} (#{s.version})"
				end.uniq.join("\n")

				UI.message "Tdfire: 添加以下代码至Podfile规避此错误: tdfire_use_source_pods #{invalid_specs.map { |s| s.root.name }}"
				raise Informative, "以下组件没有二进制版本: \n#{specs_message} " 
			end
		end
	end
end

module CocoapodsTdfireBinary
	Pod::HooksManager.register('cocoapods-tdfire-binary', :pre_install) do |context, _|
		# 使用 cocoapods package 打包，不使用 carthage 了，不用设置 share schemes
		# 如果使用 carhtage ，一定要让需要二进制化的 target shared，此 target 不能是 static framework / library ，必须是 dynamic framework.
		# 并且需要在这里做个标记，记录目标 target ，让这个 target 对应的 podspec 跳过 set_use_static_framework 这一步.
		# pod install 时，强制使用源码，然后使用  --no-skip-current iOS --no-use-binaries
		# carthage 生成 static framework 参照 https://github.com/Carthage/Carthage/blob/master/Documentation/StaticFrameworks.md
		#
		# first_target_definition = context.podfile.target_definition_list.select{ |d| d.name != 'Pods' }.first
		# development_pod = first_target_definition.name.split('_').first unless first_target_definition.nil?
    #
		# Pod::UI.section("Tdfire: auto set share scheme for development pod: \'#{development_pod}\'") do
		# 	# carthage 需要 shared scheme 构建 framework
		# 	context.podfile.install!('cocoapods', :share_schemes_for_development_pods => [development_pod])
		# end unless development_pod.nil?


		# 标明未发布的pod，因为未发布pod没有对应的二进制版本，无法下载
    # 未发布的pod，一定是源码依赖的
    Pod::UI.section("Tdfire: auto set unpublished pods") do
			Pod::Tdfire::BinaryStateStore.unpublished_pods = context.podfile.dependencies.select(&:external?).map(&:root_name)

			Pod::UI.message "> Tdfire: unpublished pods: #{Pod::Tdfire::BinaryStateStore.unpublished_pods.join(', ')}"
		end

		# 使用 static_framework ，不用 dynamic_framework ，不需要关心 dynamic_framework 的依赖链了
		#
		# 没有标识use_frameworks!，进行源码依赖需要设置Pod依赖链上，依赖此源码Pod的也进行源码依赖
		# BinaryStateStore.use_frameworks = first_target_definition.uses_frameworks?
		# unless BinaryStateStore.use_frameworks
		# 	Pod::UI.section("Tdfire: analyze chain pods depend on use source pods: #{BinaryStateStore.use_source_pods.join(', ')}") do
		# 		chain_pods = SourceChainAnalyzer.new(context.podfile).analyze(BinaryStateStore.use_source_pods)

		# 		Pod::UI.message "> Tdfire: find chain pods: #{chain_pods.join(', ')}"

		# 		BinaryStateStore.use_source_pods += chain_pods 
		# 	end unless BinaryStateStore.use_source_pods.empty? 
		# end
	end

	Pod::HooksManager.register('cocoapods-tdfire-binary', :post_install) do |context, _|
	# CocoaPods 1.5.0 修复了此问题
	#
	# fix `Shell Script` Build Phase Fails When Input / Output Files List is Too Large
	# 	Pod::UI.section('Tdfire: auto clean input and output files') do
	# 		context.umbrella_targets.map(&:user_targets).flatten.uniq.each do |t|
	#       phase = t.shell_script_build_phases.find { |p| p.name.include?(Pod::Installer::UserProjectIntegrator::TargetIntegrator::COPY_PODS_RESOURCES_PHASE_NAME) }
  #
	#       max_input_output_paths = 1000
	#       input_output_paths = phase.input_paths.count + phase.output_paths.count
	#       Pod::UI.message "Tdfire: input paths and output paths count for #{t.name} : #{input_output_paths}"
  #
	#       if input_output_paths > max_input_output_paths
	#       	phase.input_paths.clear
	#       	phase.output_paths.clear
	#       end
  #
	#     end
  #
	#     context.umbrella_targets.map(&:user_project).each do |project|
	#       project.save
	#     end
	# 	end

		Pod::UI.puts "Tdfire: all source dependency pods: #{Pod::Tdfire::BinaryStateStore.real_use_source_pods.join(', ')}" if Pod::Tdfire::BinaryStateStore.use_binary?
		Pod::UI.puts "Tdfire: all unpublished pods: #{Pod::Tdfire::BinaryStateStore.unpublished_pods.join(', ')}"
	end
end