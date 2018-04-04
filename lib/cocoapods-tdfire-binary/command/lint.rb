require 'cocoapods-tdfire-binary/binary_state_store'

module Pod
	class Command
		class Binary < Command
			class Lint < Binary
				self.abstract_command = false
				self.summary = '对本地二进制进行 Lint'
				self.description = <<-DESC
					对本地二进制进行 Lint
	      DESC

				def self.options
					[
							['--sources', '私有源地址'],
					].concat(super)
				end

				def initialize(argv)
					@sources = argv.option('sources')
					@spec_file = first_podspec
					@spec_name = @spec_file.split('/').last.split('.').first
					super
				end

				def validate!
					super
					help! '当前目录下没有podspec文件.' if @spec_file.nil?
					framework = "#{@spec_name}.framework"
					help! "当前目录下没有#{framework}文件" unless File.exist?(framework)
				end

				def run
					Tdfire::BinaryStateStore.lib_lint_binary_pod = @spec_name

					argvs = [
							"--sources=#{@sources || Tdfire::BinaryUrlManager.private_cocoapods_url}",
							'--allow-warnings',
							'--use-libraries',
							'--verbose'
					]

					lint= Pod::Command::Lib::Lint.new(CLAide::ARGV.new(argvs))
					lint.validate!
					lint.run
				end
			end
		end
	end
end