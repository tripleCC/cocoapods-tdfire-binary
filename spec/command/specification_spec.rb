require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Specification do
    it 'get recursive value' do
      spec = Specification.new do |s|
        s.framework = 'UIKit'
        s.ios.framework = 'CoreGraphics'

        s.subspec 'boy' do |ss|
          ss.framework = 'Accounts'
          ss.ios.framework = 'ARKit'
        end
      end
      spec.tdfire_recursive_value('frameworks', :ios).should == ['UIKit', 'CoreGraphics', 'Accounts', 'ARKit']
      spec.tdfire_recursive_value('frameworks', :osx).should == ['UIKit', 'Accounts']
    end
  end

  describe SpecificationRefactor = Tdfire::BinarySpecificationRefactor do
    before do
      @boy_spec = Specification::new(nil, 'Preson') do |s|
        s.public_header_files = 'boy.h'
        s.source_files = 'boy.{h,m}'
        s.resources = 'boy.png'
        s.resource_bundles = {:boy => 'boy_next_door.png' }

        s.frameworks = 'UIKit'
        s.dependency 'ReactiveX'
      end

      @girl_spec = Specification::new(nil, 'Preson') do |s|
        s.public_header_files = 'boy.h'
        s.source_files = 'boy.{h,m}'
        s.resources = 'boy.png'
        s.resource_bundles = {:boy => 'boy_next_door.png' }

        s.frameworks = 'UIKit'
        s.dependency 'ReactiveX'

        s.subspec 'Core' do |ss|
          ss.public_header_files = 'Core/Core.h'
          ss.source_files = 'Core.{h,m}'
          ss.resources = 'Core.png'
          ss.resource_bundles = {:Core => 'core_next_door.png' }

          ss.frameworks = 'CoreGraphics'
          ss.dependency 'AFNetworking'
        end

        s.subspec 'Car' do |ss|
          ss.public_header_files = 'Car/Car.h'
          ss.source_files = 'Car.{h,m}'
          ss.resources = 'Car.png'
          ss.resource_bundles = {:Car => 'car_next_door.png' }

          ss.frameworks = 'Accounts'
          ss.dependency 'SDWebImage'
          ss.dependency 'Preson/Core'
        end
      end

      @empty_spec = Specification::new(nil, 'Preson')
    end

    it 'configure binary' do
      refactor = SpecificationRefactor.new(@empty_spec)
      refactor.configure_binary(@boy_spec)

      ios_consumer = @empty_spec.consumer(:ios)
      ios_consumer.frameworks.should == ['UIKit']
      ios_consumer.dependencies.map(&:name).should == ['ReactiveX']
      ios_consumer.vendored_frameworks.should == ['Preson.framework']
    end

    it 'configure binary default subspec' do
      refactor = SpecificationRefactor.new(@empty_spec)
      refactor.configure_binary_default_subspec(@girl_spec)

      (@empty_spec.subspecs.map(&:name) - ['Preson/TdfireBinary']).should == @girl_spec.subspecs.map(&:name)
      ios_consumer = @empty_spec.subspecs.select { |s| s.name == 'Preson/TdfireBinary' }.first.consumer(:ios)
      ios_consumer.frameworks.should == ['UIKit', 'CoreGraphics', 'Accounts']
      ios_consumer.dependencies.map(&:name).should == ['ReactiveX', 'AFNetworking', 'SDWebImage']
      ios_consumer.vendored_frameworks.should == ['Preson.framework']
    end

    it 'set preserve paths' do
      refactor = SpecificationRefactor.new(@empty_spec)
      refactor.set_preserve_paths(@boy_spec)

      preserve_paths = ['Preson.framework']
      preserve_paths += ['boy.{h,m}', 'boy.png', 'boy_next_door.png']
      @empty_spec.consumer(:ios).preserve_paths.sort.should == preserve_paths.sort

      refactor = SpecificationRefactor.new(@empty_spec)
      refactor.set_preserve_paths(@girl_spec)
      preserve_paths += ['Core.{h,m}', 'Core.png', 'core_next_door.png']
      preserve_paths += ['Car.{h,m}', 'Car.png', 'car_next_door.png']
      @empty_spec.consumer(:ios).preserve_paths.sort.should == preserve_paths.sort
    end
  end
end