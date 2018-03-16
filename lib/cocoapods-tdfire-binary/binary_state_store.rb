module  Tdfire
	class BinaryStateStore
		public

		def self.printed_pods
			@printed_pods ||= []
		end

		def self.use_source_pods
			String(ENV[USE_SOURCE_PODS_KEY]).split('|')
		end

		def self.use_source_pods=(pods)
			ENV[USE_SOURCE_PODS_KEY] = Array(pods).join('|')
		end

		def self.use_binary?
			ENV[USE_BINARY_KEY] == USE_BINARY_SURE_VALUE
		end

		def self.set_use_binary
			ENV[USE_BINARY_KEY] = USE_BINARY_SURE_VALUE
		end

		private

		USE_SOURCE_PODS_KEY = 'tdfire_use_source_pods'
		USE_BINARY_KEY = 'tdfire_use_binary'
		USE_BINARY_SURE_VALUE = '1'
	end
end
