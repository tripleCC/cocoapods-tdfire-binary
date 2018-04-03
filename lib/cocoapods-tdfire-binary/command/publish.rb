module Pod
  class Command
    class Binary < Command
      class Publish < Binary
        self.abstract_command = false
        self.summary = '正式发布二进制组件'
        self.description = <<-DESC
					正式发布二进制组件版本
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME.podspec', false),
        ]

        def self.options
          [
            ['--commit="Fix some bugs"', '发布的 commit 信息']
          ].concat(super)
        end

        def initialize(argv)
          spec_file = argv.shift_argument
          @commit = argv.option('commit')

          spec_file = first_podspec if spec_file.nil?
          @spec_file = spec_file
          super
        end

        def validate!
          super
          help! "当前目录下找不到有效的 podspec 文件" if @spec_file.nil?
        end

        def run
          spec = Specification.from_file(@spec_file)

          UI.section("Tdfire: start publishing #{spec.name} ...") do
            argvs = [
                fire_sources.first.name,
                @spec_file,
                '--allow-warnings',
                '--use-libraries',
                '--verbose'
            ]
            argvs << %Q[--commit-message=#{commit_prefix(spec) + "\n" + @commit}] unless @commit.to_s.empty?

            push = Pod::Command::Repo::Push.new(CLAide::ARGV.new(argvs))
            push.validate!
            push.run
          end
        end

        private
        def commit_prefix(spec)
          output_path = fire_sources.first.pod_path(spec.name) + spec.version.to_s
          if output_path.exist?
            message = "[Fix] #{spec}"
          elsif output_path.dirname.directory?
            message = "[Update] #{spec}"
          else
            message = "[Add] #{spec}"
          end
        end
      end
    end
  end
end