require 'cocoapods-tdfire-binary/binary_state_store'
require 'cocoapods-tdfire-binary/source_chain_analyzer'

module CocoapodsTdfireBinary
	include Tdfire

	Pod::HooksManager.register('cocoapods-tdfire-binary', :pre_install) do |context, _|
		first_target_definition = context.podfile.target_definition_list.select{ |d| d.name != 'Pods' }.first
		development_pod = first_target_definition.name.split('_').first unless first_target_definition.nil?

		Pod::UI.section("Tdfire: auto set share scheme for development pod: \'#{development_pod}\'") do
			# carthage 需要 shared scheme 构建 framework
			context.podfile.install!('cocoapods', :share_schemes_for_development_pods => [development_pod])
		end unless development_pod.nil?


		# 标明未发布的pod，因为未发布pod没有对应的二进制版本，无法下载
    # 未发布的pod，一定是源码依赖的
    Pod::UI.section("Tdfire: auto set unpublished pods") do
			BinaryStateStore.unpublished_pods = context.podfile.dependencies.select(&:external?).map(&:root_name)

			Pod::UI.message "> Tdfire: unpublished pods: #{BinaryStateStore.unpublished_pods.join(', ')}"
		end

		# 没有标识use_frameworks!，进行源码依赖需要设置Pod依赖链上，依赖此源码Pod的也进行源码依赖
		BinaryStateStore.use_frameworks = first_target_definition.uses_frameworks?
		unless BinaryStateStore.use_frameworks
			Pod::UI.section("Tdfire: analyze chain pods depend on use source pods: #{BinaryStateStore.use_source_pods.join(', ')}") do
				chain_pods = SourceChainAnalyzer.new(context.podfile).analyze(BinaryStateStore.use_source_pods)

				Pod::UI.message "> Tdfire: find chain pods: #{chain_pods.join(', ')}"

				BinaryStateStore.use_source_pods += chain_pods 
			end unless BinaryStateStore.use_source_pods.empty? 
		end
	end

	#fix `Shell Script` Build Phase Fails When Input / Output Files List is Too Large
	Pod::HooksManager.register('cocoapods-tdfire-binary', :post_install) do |context, _|
		Pod::UI.section('Tdfire: auto clean input and output files') do
			context.umbrella_targets.map(&:user_targets).flatten.uniq.each do |t|
	      phase = t.shell_script_build_phases.find { |p| p.name.include?(Pod::Installer::UserProjectIntegrator::TargetIntegrator::COPY_PODS_RESOURCES_PHASE_NAME) }

	      max_input_output_paths = 1000
	      input_output_paths = phase.input_paths.count + phase.output_paths.count
	      Pod::UI.message "Tdfire: input paths and output paths count for #{t.name} : #{input_output_paths}"

	      if input_output_paths > max_input_output_paths
	      	phase.input_paths.clear
	      	phase.output_paths.clear
	      end

	    end

	    context.umbrella_targets.map(&:user_project).each do |project|
	      project.save
	    end
		end

		Pod::UI.puts "Tdfire: all source dependency pods: #{BinaryStateStore.real_use_source_pods.join(', ')}" if BinaryStateStore.use_binary?
		Pod::UI.puts "Tdfire: all unpublished pods: #{BinaryStateStore.unpublished_pods.join(', ')}"
	end
end