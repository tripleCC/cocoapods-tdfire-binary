require 'colored2'
require 'fileutils'
require 'cocoapods_packager'
require 'cocoapods-tdfire-binary/binary_url_manager'
require 'cocoapods-tdfire-binary/binary_state_store'
require 'cocoapods-tdfire-binary/binary_specification_refactor'
require 'cocoapods-bin'

module Pod
	class Command
		class Binary < Command
			class Package < Binary
        self.abstract_command = false
				self.summary = '二进制打包'
				self.description = <<-DESC
					将源码打包成二进制，并压缩成 zip 包
	      DESC

	      def self.options
          [
            ['--clean', '执行成功后，删除 zip 文件外的所有生成文件'],
            ['--spec-sources', '私有源地址'],
            # ['--local', '使用本地代码'],
            ['--use-carthage', 'carthage使用carthage进行打包，三方库提供carthage的优先'],
						['--subspecs', '打包子组件'],
						['--binary-first', '二进制优先']
          ].concat(super)
        end

	      def initialize(argv)
	      	@clean = argv.flag?('clean')
          @local = argv.flag?('local')
          @use_carthage = argv.flag?('use-carthage')
	      	@spec_sources = argv.option('spec-sources') || [:binary_source, :code_source].map { |m| Config.instance.sources_manager.send(m) }.map(&:url).join(',')
					@subspecs= argv.option('subspecs')
	      	@spec_file = first_podspec
	      	@binary_first = argv.flag?('binary-first')
	      	super
	      end

        def validate!
          super
          help! '当前目录下没有podspec文件.' if @spec_file.nil?
        end

        def run
					if @use_carthage
						build_by_carthage
					else
						build_by_pod_packager
					end
        end

        private
				def build_by_pod_packager
					# 组件有多个 platform 时，限制 cocoapods-packager 只打 ios 代码
					Pod::Tdfire::BinaryStateStore.limit_platform = true
					ENV['use_binaries'] = 'true'
					ENV['use_plugins'] = 'cocoapods-bin'

					spec = Specification.from_file(@spec_file)
					prepare(spec)

					if @binary_first
						Pod::Tdfire::BinaryStateStore.unpublished_pods = Pod::Tdfire::BinaryStateStore.unpublished_pods + Array(spec.name)
						Pod::Tdfire::BinaryStateStore.set_use_binary
					end

					package(spec)
					zip_packager_framework(spec)

					Pod::Tdfire::BinaryStateStore.limit_platform = false
				end

				def build_by_carthage
					build_script = <<-EOF
if [[ -d swift-staticlibs ]]; then
	rm -fr swift-staticlibs 
fi

if [[ ! $(command -v carthage) ]]; then
	brew install carthage 
fi

git clone git@git.2dfire-inc.com:cocoapods-repos/swift-staticlibs.git					

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
trap 'rm -f "$xcconfig"' INT TERM HUP EXIT

echo "LD = $PWD/swift-staticlibs/ld.py" >> $xcconfig
echo "DEBUG_INFORMATION_FORMAT = dwarf" >> $xcconfig

export XCODE_XCCONFIG_FILE="$xcconfig"

carthage build "$@" --no-skip-current --platform iOS

rm -fr swift-staticlibs
					EOF

					system build_script

					spec = Specification.from_file(@spec_file)
					zip_carthage_framework(spec)
				end


        def prepare(spec)
          UI.section("Tdfire: prepare for packaging ...") do
            clean(spec)
          end
        end

        def package(spec)
        	UI.section("Tdfire: package #{spec.name} ...") do
            argvs = [
                "#{spec.name}.podspec",
                "--exclude-deps",
                "--force",
                "--no-mangle",
                "--spec-sources=#{@spec_sources || Pod::Tdfire::BinaryUrlManager.private_cocoapods_url}",
            ]

            argvs << "--local" if @local
						argvs << "--subspecs=#{@subspecs}" unless @subspecs.nil?

            package = Pod::Command::PackagePro.new(CLAide::ARGV.new(argvs))
            package.validate!
            package.run
	        end
        end

        def zip_packager_framework(spec)
					framework_directory = "#{spec.name}-#{spec.version}/ios"
					framework_name = "#{spec.name}.framework"
					framework_path = "#{framework_directory}/#{framework_name}"

        	raise Informative, "没有需要压缩的 framework 文件：#{framework_path}" unless File.exist?(framework_path)

					# cocoapods-packager 使用了 --exclude-deps 后，虽然没有把 dependency 的符号信息打进可执行文件，但是它把 dependency 的 bundle 给拷贝过来了 (builder.rb 229 copy_resources)
					# 这里把多余的 bundle 删除
					# https://github.com/CocoaPods/CocoaPodsds-packager/pull/199
					resource_bundles = spec.tdfire_recursive_value('resource_bundles').map(&:keys).flatten.uniq
					resources= spec.tdfire_recursive_value('resources').map { |r| r.split('/').last }
					FileUtils.chdir("#{framework_path}/Versions/A/Resources") do
						dependency_bundles = Dir.glob('*.bundle').select do |b|
							!resource_bundles.include?(b.split('.').first) && !resources.include?(b)
						end
						unless dependency_bundles.empty?
							Pod::UI::puts "Tdfire: remove dependency bundles: #{dependency_bundles.join(', ')}"

							dependency_bundles.each do |b|
								FileUtils.rm_rf(b)
							end
						end
					end if File.exist? "#{framework_path}/Versions/A/Resources"

        	zip_framework(spec, framework_directory)

					clean(spec) if @clean
				end

				def zip_carthage_framework(spec)
					framework_directory = "Carthage/Build/iOS"
					framework_name = "#{spec.name}.framework"
					framework_path = "#{framework_directory}/#{framework_name}"

					raise Informative, "没有需要压缩的 framework 文件：#{framework_path}" unless File.exist?(framework_path)

					zip_framework(spec, framework_directory)
				end

				def zip_framework(spec, framework_directory)
					framework_name = "#{spec.name}.framework"
					output_name = "#{framework_name}.zip"
					UI.section("Tdfire: zip #{framework_directory}/#{framework_name} ...") do
						FileUtils.chdir(framework_directory) do
							system "zip --symlinks -r #{output_name} #{framework_name}"
							system "mv #{output_name} #{framework_directory.split('/').count.times.reduce("") { |r, n| r + "../" }}"
						end
					end

					Pod::UI::puts "Tdfire: save framework zip file to #{Dir.pwd}/#{output_name}".green
				end

        def clean(spec)
          file = "#{spec.name}-#{spec.version}"

          UI.message "Tdfire: cleaning #{file}"
          system "rm -fr #{spec.name}-#{spec.version}" if File.exist?(file)
        end

			end
		end
	end
end