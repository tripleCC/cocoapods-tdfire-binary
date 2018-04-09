
module Pod
  module Tdfire
    class BinaryStateStore
      public

      class << self
        # attr_accessor :unpublished_pods
        attr_accessor :use_source_pods
        attr_reader :printed_pods
        attr_accessor :use_frameworks
        attr_accessor :use_source
        attr_accessor :lib_lint_binary_pod
      end

      @use_source_pods = []
      @use_binary_pods = []
      @printed_pods = []
      @use_frameworks = false

      def self.real_use_source_pods
        (@use_source_pods + unpublished_pods).uniq
      end

      def self.unpublished_pods
        String(ENV[UNPBLISHED_PODS]).split('|').uniq
      end

      def self.unpublished_pods=(pods)
        ENV[UNPBLISHED_PODS] = Array(pods).uniq.join('|')
      end

      def self.use_binary?
        ENV[USE_BINARY_KEY] == USE_SURE_VALUE
      end

      def self.set_use_binary
        ENV[USE_BINARY_KEY] = USE_SURE_VALUE
      end

      def self.force_use_binary?
        ENV[FORCE_USE_BINARY_KEY] == USE_SURE_VALUE
      end

      def self.set_force_use_binary
        ENV[FORCE_USE_BINARY_KEY] = USE_SURE_VALUE
      end

      def self.unset_force_use_binary
        ENV[FORCE_USE_BINARY_KEY] = '0'
      end

      def self.force_use_source?
        ENV[FORCE_USE_SOURCE_KEY] == USE_SURE_VALUE
      end

      private

      UNPBLISHED_PODS = "tdfire_unpublished_pods"
      FORCE_USE_SOURCE_KEY = 'tdfire_force_use_source'
      FORCE_USE_BINARY_KEY = 'tdfire_force_use_binary'
      USE_BINARY_KEY = 'tdfire_use_binary'
      USE_SURE_VALUE = '1'
    end
  end
end
