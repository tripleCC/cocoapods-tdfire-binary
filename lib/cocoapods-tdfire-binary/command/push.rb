
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
	class Command
		class Binary < Command
			class Push < Binary
				ZIP_SUBFFIX = '.framework.zip'

				self.abstract_command = false
				self.summary = '推送二进制 zip 包'
				self.description = <<-DESC
					将二进制 zip 包推送至二进制服务器
	      DESC

	      self.arguments = [
          CLAide::Argument.new('PATH', false)
        ]

         def self.options
          [
            ['--name=组件名', '推送二进制的组件名'],
            ['--version=版本号', '推送二进制的版本号'],
            ['--commit=版本日志', '推送二进制的版本日志'],
          ].concat(super)
        end

	      def initialize(argv)
	      	path = argv.shift_argument
	      	name = argv.option('name')
	      	version = argv.option('version')
	      	commit = argv.option('commit')
	      	
	      	unless first_podspec.nil? 
	      		if path.nil?
			      	path = first_podspec.split('.').first 
			      end

			      spec = Specification.from_file(Pathname.new(first_podspec))
		      	version = spec.version if version.nil?
						name = spec.name 
	      	end

		      path += ZIP_SUBFFIX unless path.end_with?(ZIP_SUBFFIX)


	      	@path = path
	      	@name = name || path.split('/').last - ZIP_SUBFFIX
	      	@version = version
	      	@commit = commit
	      	super
	      end

	      def validate!
          super
          help! "指定目录下没有可推送文件: #{@path}" unless File.exist?(@path)
          help! "必须为推送组件指定版本(--version)" if @version.nil?
        end

	      def run
					tag_log = `git tag -l -n #{@version}` 	      	
					tag_log = tag_log.split(' ')[1..-1].join('') unless tag_log.empty?
					

					hash_log =  `git show-ref #{@version}`
					hash_log = hash_log.split(' ').first unless hash_log.empty?

					commit = @commit || tag_log || @version

					UI.section("Tdfire: start pushing framework zip file ...") do
						UI.puts "Tdfire: post argvs: name -> #{@name}, version -> #{@version}, path -> #{@path}, commit -> #{commit}, commit hash -> #{hash_log}"
						Pod::Tdfire::BinaryUrlManager.post_push_url(@name, @version, @path, commit, hash_log)
					end
        end
			end
		end
	end
end