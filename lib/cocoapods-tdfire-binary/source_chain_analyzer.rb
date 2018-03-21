module Tdfire
	class SourceChainAnalyzer

		def initialize(podfile)
			@lockfile = generate_lockfile(podfile)
			@pods_data = @lockfile.internal_data['PODS']
			@parent_pods = []
		end

		public

		def analyze(pods)
			pods.each do |pod|
				find_parent_pods(pod, @pods_data) unless @parent_pods.include?(pod)
			end unless @lockfile.nil?

			@parent_pods.map{ |pod| pod.split('/', 2).first }.uniq
		end

		private

		def find_parent_pods(pod, pods_data)
			return if pod.nil?

			parent_pod_hashes = pods_data.select{ |pod_data| pod_data.is_a?(Hash) && pod_data.values.flatten.include?(pod) }
			parent_pod_hashes.each do |hold_pod_hash|
				hold_pod_name = hold_pod_hash.keys.first.split('(').first.strip	
				@parent_pods << hold_pod_name
				find_parent_pods(hold_pod_name, pods_data - parent_pod_hashes)
			end
		end

		def generate_lockfile(podfile)
			fetch_external_source = false

			lockfile = Pod::Lockfile.from_file(Pathname.new('Podfile.lock'))

			# 如果手动去删除 Pods/Local Podspecs 里面的文件，那就会直接报错了
			if lockfile.nil? || !Pathname.new('Pods').exist?
				fetch_external_source = true
			else
				external = podfile.dependencies.select(&:external?)
				external_source = {}
				external.each { |d| external_source[d.root_name] = d.external_source }
				lockfile_external_source = lockfile.internal_data['EXTERNAL SOURCES']
				fetch_external_source = external_source != lockfile_external_source
			end

			sandbox = Pod::Config.instance.sandbox
			analyzer = Pod::Installer::Analyzer.new(sandbox, podfile, lockfile)			
			specs = Pod::Config.instance.with_changes(skip_repo_update: true) do 
				# allow fetch ，初次install时，或者新增external source 时，由于Pods/Local Podspecs 是空，会抛出找不到specification异常
				begin
					analyzer.analyze(fetch_external_source).specs_by_target.values.flatten(1)	
				rescue 
					Pod::UI.message "> Tdfire: allow to fetch external source and try again".yellow
					analyzer.analyze(true).specs_by_target.values.flatten(1)
				end
			end

			Pod::Lockfile.generate(podfile, specs, {}) || lockfile
		end

	end
end