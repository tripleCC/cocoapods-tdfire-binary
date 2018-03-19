require 'cocoapods-tdfire-binary/binary_state_store'

module CocoapodsTdfireBinary
	
	tdfire_default_development_pod = nil
	Pod::HooksManager.register('cocoapods-tdfire-binary', :pre_install) do |context, _|
		first_target_definition = context.podfile.target_definition_list.select{ |d| d.name != 'Pods' }.first
		development_pod = first_target_definition.name.split('_').first unless first_target_definition.nil?

		Pod::UI.section("Tdfire: set share scheme for development pod: \'#{development_pod}\'") do
			# carthage 需要 shared scheme 构建 framework
			context.podfile.install!('cocoapods', :share_schemes_for_development_pods => [development_pod])
		end unless development_pod.nil?

		# 在采用二进制依赖，并且不是强制二进制依赖的情况下，当前打成 framework 的开发 Pod 需要源码依赖
		if Tdfire::BinaryStateStore.use_binary? && !Tdfire::BinaryStateStore.force_use_binary?
			Pod::UI.section("Tdfire: set use source for development_pod: \'#{development_pod}\'") do 
				# 开发 Pod 使用源码依赖
				Tdfire::BinaryStateStore.use_source_pods = Array(development_pod) + Tdfire::BinaryStateStore.use_source_pods
			end unless development_pod.nil?
			tdfire_default_development_pod = development_pod
		end
	end

	#fix `Shell Script` Build Phase Fails When Input / Output Files List is Too Large
	Pod::HooksManager.register('cocoapods-tdfire-binary', :post_install) do |context, _|
		Pod::UI.section('Tdfire: clean input and output files') do
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

		# 在采用二进制依赖，并且不是强制二进制依赖的情况下，提醒当前工程的所有开发 Pods 需要设置成源码依赖
		if Tdfire::BinaryStateStore.use_binary? && !Tdfire::BinaryStateStore.force_use_binary?
			all_development_pods = context.sandbox.development_pods.keys - Array(tdfire_default_development_pod) - Tdfire::BinaryStateStore.use_source_pods
			all_development_pods_displayed_text = all_development_pods.map { |p| "'#{p}'" }.join(',')
			Pod::UI.puts "Tdfire: You should add following code to your `Podfile`, and then run `pod install or pod update` again. \n\ntdfire_use_source_pods [#{all_development_pods_displayed_text}]\n".cyan unless all_development_pods.empty?
		end

		Pod::UI.puts "Tdfire: all source dependency pods: #{Tdfire::BinaryStateStore.use_source_pods.join(', ')}"
	end
end