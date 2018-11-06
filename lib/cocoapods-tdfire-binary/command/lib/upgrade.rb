require 'cocoapods'
require 'cocoapods-tdfire-binary/binary_url_manager'

module Pod
  class Command
    class Binary < Command
      class Lib < Binary
      	class Upgrade < Lib
      		self.abstract_command = false
	        self.summary = '更新 podspec 版本'
	        self.description = <<-DESC
						更新 podspec 版本
	        DESC

	        def self.options
					[
							['--type', '更新版本类型，patch/minor/major'],
							['--version', '更新版本号，优先级比 --type 高'],
							['--commit', '提交 commit 日志，没有设置则不 add']
					].concat(super)
					end

	        def initialize(argv)
	        	@type = argv.option('type') || 'patch'
	        	@version = argv.option('version')
	        	@commit = argv.option('commit')
	        	@spec_file = first_podspec
	          super
	        end

	        def validate!
	          super
	          help! '当前目录下没有podspec文件.' if @spec_file.nil?
	        end

	        def run
	        	path = Pathname.new(@spec_file)
	        	spec = Pod::Specification.from_file(path)
          	version = unit_increase_version(spec.version, @type)
          	version = @version if @version

	          UI.section("Tdfire: upgrade podspec version to #{version} ...") do
	          	spec_string = File.read(Pathname.new(@spec_file))
	          	spec_content = update_podspec_content(spec_string, version)
	          	File.open(path, "w") do |io|  
				        io << spec_content
				      end 

				      if @commit
				      	`git add #{path}`
				      	`git commit -m "#{@commit}"` 
				      end
	          end
	        end

	        def update_podspec_content(podspec_content, version)
						require_variable_prefix = true
						version_var_name = 'version'
						variable_prefix = require_variable_prefix ? /\w\./ : //
						version_regex = /^(?<begin>[^#]*#{variable_prefix}#{version_var_name}\s*=\s*['"])(?<value>(?<major>[0-9]+)(\.(?<minor>[0-9]+))?(\.(?<patch>[0-9]+))?(?<appendix>(\.[0-9]+)*)?(-(?<prerelease>(.+)))?)(?<end>['"])/i

						version_match = version_regex.match(podspec_content)
					  updated_podspec_content = podspec_content.gsub(version_regex, "#{version_match[:begin]}#{version}#{version_match[:end]}")
					  updated_podspec_content
					end

	        def unit_increase_version(version, type)
					  major = version.major
					  minor = version.minor
					  patch = version.patch
					  case type
					  when 'major'
					    major += 1
					  when 'minor'
					    minor += 1
					  when 'patch'
					    patch += 1
					  else
					  end
					  Pod::Version.new("#{major}.#{minor}.#{patch}")
					end
      	end
      end
    end
  end
end