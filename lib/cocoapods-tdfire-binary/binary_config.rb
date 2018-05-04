
require 'yaml'

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
        setting = {}
        if File.exist?(binary_setting_file)
          setting = YAML.load_file(binary_setting_file)
        end
        setting
      end

      def binary_setting_file
        config.home_dir + 'binary_config.yml'
      end

      def config_with_setting(setting)
        File.open(binary_setting_file, "w+") do |f|
          f.write(setting.to_yaml)
        end
      end

      private

      def config
        Config.instance
      end

      def setting_for_key(key)
        if !binary_setting_file.exist?
          raise Pod::Informative, "获取不到配置信息，执行 pod binary init 初始化配置信息."
        end

        setting = setting_hash[key]
        if setting.nil?
          raise Pod::Informative, "获取不到 #{key} 的配置信息，执行 pod binary init 或手动在 #{binary_setting_file} 设置."
        end
        setting
      end

    end
  end
end
