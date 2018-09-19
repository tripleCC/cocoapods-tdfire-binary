require 'cocoapods-tdfire-binary/binary_state_store'

module Pod
	class Command
		class Binary < Command
			class Lint < Binary
				self.abstract_command = false
				self.summary = '对本地组件进行 Lint'
				self.description = <<-DESC
					对本地组件进行 Lint
	      DESC

				def self.options
					[
							['--sources', '私有源地址'],
							# ['--clean', '执行成功后，删除 zip 文件外的所有生成文件'],
							['--binary-first', '二进制优先'],
							['--subspec', 'lint 特定 subspec']
					].concat(super)
				end

				def initialize(argv)
					@clean = argv.flag?('clean')
					@sources = argv.option('sources')
					@subspec = argv.option('subspec')
					@binary_first = argv.flag?('binary-first')

					@spec_file = first_podspec
					@spec_name = @spec_file.split('/').last.split('.').first unless @spec_file.nil?
					# unzip_framework
					super
				end

				def validate!
					super
					help! '当前目录下没有podspec文件.' if @spec_file.nil?
					# framework = "#{@spec_name}.framework"
					# help! "当前目录下没有#{framework}文件" unless File.exist?(framework)
				end

				# def unzip_framework
				# 	framework = "#{@spec_name}.framework"
				# 	zip_name = "#{framework}.zip"
				# 	if File.exist?(zip_name) && !File.exist?("#{@spec_name}.framework")
				# 		system "unzip #{zip_name}"
				# 	end
				# end

				def run
					if @binary_first
						Pod::Tdfire::BinaryStateStore.unpublished_pods = Pod::Tdfire::BinaryStateStore.unpublished_pods + Array(@spec_name)
						Pod::Tdfire::BinaryStateStore.set_use_binary
					end

					argvs = [
							"--sources=#{@sources || Pod::Tdfire::BinaryUrlManager.private_cocoapods_url}",
							'--allow-warnings',
							'--use-libraries',
							'--verbose'
					]

					argvs << "--subspec=#{@subspec}" unless @subspec.nil?

					lint= Pod::Command::Lib::Lint.new(CLAide::ARGV.new(argvs))
					lint.validate!
					lint.run

					# system "rm -fr #{@spec_name}.framework " if @clean
				end
			end
		end
	end
end