require 'fileutils'
require 'colored2'
require 'cocoapods-tdfire-binary/specification_dsl'
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
	class Installer
		old_resolve_dependencies = instance_method(:resolve_dependencies)
		define_method(:resolve_dependencies) do 
			old_resolve_dependencies.bind(self).call()

      # 1.4.0 版本生效
      # 使用 use_frameworks! 后，生成静态 Framework
      analysis_result.specifications.each do |spec|
        spec.static_framework = true if spec.respond_to?('static_framework')
      end if Pod::Tdfire::BinaryStateStore.use_binary?

      cleaner = Pod::Tdfire::BinaryCacheCleaner.new(analysis_result)
      cleaner.clean!
			
      # 二进制不存在，强制进行源码依赖
			if cleaner.no_binary_specs.any?
				pods = cleaner.no_binary_specs.map { |s| s.root.name }
				Pod::Tdfire::BinaryStateStore.use_source_pods += pods
        UI.warn "Tdfire: 以下组件没有二进制版本，将强制使用源码依赖，添加以下代码至Podfile规避此警告: tdfire_use_source_pods #{pods}"
        
        # 在这个时间点设置 use_source_pods ，实际上并不会生效，因为 analysis_result 已经生成，依赖关系不会改变
        # 所以这里强制进行第二次分析，更新 analysis_result
        old_resolve_dependencies.bind(self).call()
      end
		end
	end
end

module Pod
  module Tdfire
    class BinaryCacheCleaner
      attr_reader :use_binary_specs

      def initialize(analysis_result)
        @analysis_result = analysis_result
        @use_binary_specs = analysis_result.specifications.uniq { |s| s.root.name }.reject(&:tdfire_use_source?)
      end

      def clean!
        # 判断有效组件的 cache 中是否有二进制，没有的话，删除组件缓存
        specs = use_binary_specs - no_binary_specs

        return if specs.empty?

        UI.section 'Tdfire: 处理没有二进制版本的组件' do
          specs.each do |s|
            # 处理 cache
            clean_pod_cache(s)
            
            # 处理 Pods 
            clean_local_cache(s)
          end
        end
      end

      def no_binary_specs
        @invalid_specs ||= begin 
          use_binary_specs.reject do |s|
            json_string = Pod::Tdfire::BinaryUrlManager.search_binary(s.root.name)

            begin
              pod = JSON.parse(json_string, object_class: OpenStruct)
            rescue JSON::ParserError => err
              pod = OpenStruct.new
              UI.message "获取 #{s.root.name} 二进制信息失败, 具体信息 #{err}".red
            end
            versions = pod.versions || []
            versions.include?(s.version.to_s)
          end
        end
      end

      private

      def cache_descriptors
        @cache_descriptors ||= begin
          cache = Downloader::Cache.new(Config.instance.cache_root + 'Pods')
          cache_descriptors = cache.cache_descriptors_per_pod
        end
      end

      def clean_local_cache(spec)
        pod_dir = Config.instance.sandbox.pod_dir(spec.root.name)
        framework_file = pod_dir + "#{spec.root.name}.framework"
        if pod_dir.exist? && !framework_file.exist?
          UI.message "Tdfire: 删除本地 Pods 目录下缺少二进制的组件 #{spec.root.name}"

          # 设置沙盒变动标记，去 cache 中拿
          # 只有 :changed 、:added 两种状态才会重新去 cache 中拿
          @analysis_result.sandbox_state.add_name(spec.name, :changed)
          begin
            FileUtils.rm_rf(pod_dir)
          rescue => err
            puts err
          end
        end
      end

      def clean_pod_cache(spec)
        descriptors = cache_descriptors[spec.root.name]
        return if descriptors.nil?

        descriptors = descriptors.select { |d| d[:version] == spec.version}
        descriptors.each do |d|
          # pod cache 文件名由文件内容的 sha1 组成，由于生成时使用的是 podspec，获取时使用的是 podspec.json 
          # 导致生成的文件名不一致
          # Downloader::Request slug
          # cache_descriptors_per_pod 表明，specs_dir 中都是以 .json 形式保存 spec
          slug = d[:slug].dirname + "#{spec.version}-#{spec.checksum[0, 5]}"
          framework_file = slug + "#{spec.root.name}.framework"
          unless (framework_file.exist?)
            UI.message "Tdfire: 删除缺少二进制的 Cache #{spec.root.name}"
            begin
              FileUtils.rm(d[:spec_file])
              FileUtils.rm_rf(slug)
            rescue => err
              puts err
            end
          end
        end
      end
    end
  end
end