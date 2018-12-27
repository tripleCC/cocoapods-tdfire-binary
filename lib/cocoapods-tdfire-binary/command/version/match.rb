require 'cocoapods'
require 'cocoapods-tdfire-binary/command/version/match'
module Pod
	class Command
		class Binary < Command
			class Version < Binary
				class Match < Version 
					self.summary = '匹配私有源最新的版本.'

          self.description = <<-DESC
          会对当前Podfile中的组件和对应私有源中的组件的最新版本进行校对
          DESC

          attr_reader :source

          def self.options
	          [
	            ['--update-source', '更新私有源'],
	          ].concat(super)
	        end

          def initialize(argv)
          	@update_source = argv.flag?('update-source')
          	@source = private_sources.first
          	super 
          end

          def validate!
	          super
	          verify_podfile_exists!
	        end

	        def print_untagged_pod
	        	external_names = config.podfile.dependencies.select(&:external?).map(&:name)
	        	if external_names.any?
	        		puts "\n以下组件版本没有打tag："    
	            puts "============================================" 
	            puts external_names.reduce("") { |result, pod|
	              versions = source.versions(pod)
	              version = versions.sort.last if versions
	              pod = pod + "\t（最新版本 #{version.to_s}）" if version
	              result << pod + "\n"
	            }
	            puts "============================================" 
	        	end
	        end

	        def print_unmatched_newest_dependencies
	        	tagged_dependencies = config.podfile.dependencies.reject(&:external?)
	        	if tagged_dependencies.any?
	        		unmatched_newest_dependencies = tagged_dependencies.reject do |dep|
	        			versions = source.versions(dep.name) || source.versions(dep.name.split('/').first)
	        			version = versions && versions.sort.last 
	        			dep.requirement === version if version
	        		end

	        		if unmatched_newest_dependencies.any?
	        			puts "\n以下组件没有 match 最新版本："    
		            puts "============================================" 
	        			puts unmatched_newest_dependencies.reduce("") { |result, dep|
		              versions = source.versions(dep.name) || source.versions(dep.name.split('/').first)
		              version = versions.sort.last if versions
		              result << ("%-50s %s %-15s %s %s\n" % [dep.name, '=> 当前：', dep.requirement, '最新：', version])
		            }
		            puts "============================================" 
	        		end
	        	end
	        end

	        def run 
	        	private_sources.each { |s| s.update(true) } if @update_source

						print_untagged_pod	 
						print_unmatched_newest_dependencies       	
	        end
				end
			end
		end
	end
end