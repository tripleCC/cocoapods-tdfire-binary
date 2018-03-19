module  Tdfire
	class BinaryStateStore
		public

		class << self
			attr_accessor :unpublished_pods
			attr_writer :use_source_pods
			attr_reader :printed_pods
		end
		@unpublished_pods = []
		@use_source_pods = []
		@printed_pods = []

		def self.use_source_pods
			(@use_source_pods + @unpublished_pods).uniq			
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

		def self.force_use_source?
			ENV[FORCE_USE_SOURCE_KEY] == USE_SURE_VALUE
		end

		def self.auto_set_default_unpublished_pod?
			ENV[AUTO_SET_DEFAULT_UNPUBLISHED_POD_KEY]	== USE_SURE_VALUE 
		end

		def self.set_auto_set_default_unpublished_pod
			ENV[AUTO_SET_DEFAULT_UNPUBLISHED_POD_KEY]	= USE_SURE_VALUE 
		end

		private
		
		AUTO_SET_DEFAULT_UNPUBLISHED_POD_KEY = 'auto_set_default_unpublished_pod'
		FORCE_USE_SOURCE_KEY = 'tdfire_force_use_source'
		FORCE_USE_BINARY_KEY = 'tdfire_force_use_binary'
		USE_BINARY_KEY = 'tdfire_use_binary'
		USE_SURE_VALUE = '1'
	end
end
