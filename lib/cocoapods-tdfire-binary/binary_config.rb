require 'yaml'
require 'fileutils'

module Pod
  module Tdfire
    class BinaryConfig
      public

      REPO_URL_KEY = "repo_url"
      SERVER_ROOT_KEY = "server_host"
      TEMPLATE_URL_KEY = "template_url"

      def self.instance
        @instance ||= new
      end

      def repo_url
        setting_for_key(REPO_URL_KEY)
      end

      def server_host
        setting_for_key(SERVER_ROOT_KEY)
      end

      def template_url
        setting_for_key(TEMPLATE_URL_KEY)
      end

      def setting_hash
        @setting ||= begin
          if File.exist?(binary_setting_file)
            setting = YAML.load_file(binary_setting_file)
          end
        end
        @setting
      end

      def setting_file_name
        'binary_config.yml'
      end

      def binary_setting_file
        config.home_dir + setting_file_name
      end

      def config_with_setting(setting)
        File.open(binary_setting_file, "w+") do |f|
          f.write(setting.to_yaml)
        end
      end

      def private_sources(keywords = repo_url)
        config.sources_manager.all.select do |source|
          source.url.downcase.include? keywords
        end
      end

      private

      def config
        Config.instance
      end

      def setting_for_key(key)
        validate_setting_file

        setting = setting_hash[key]
        if setting.nil?
          raise Pod::Informative, "获取不到 #{key} 的配置信息，执行 pod binary init 或手动在 #{binary_setting_file} 设置."
        end
        setting
      end

      def validate_setting_file
        if !binary_setting_file.exist?
          # 公司内部就不用自己配置了
          sources = private_sources('2dfire')
          if sources.length > 0
            FileUtils.cd(config.home_dir) do
              `git clone http://git.2dfire-inc.com/qingmu/cocoapods-tdfire-binary-config`

              FileUtils.mv("cocoapods-tdfire-binary-config/#{setting_file_name}", ".")
              FileUtils.rm_rf(config.home_dir + "cocoapods-tdfire-binary-config")
            end
          else
            raise Pod::Informative, "获取不到配置信息，执行 pod binary init 初始化配置信息."
          end
        end

      end

    end
  end
end
