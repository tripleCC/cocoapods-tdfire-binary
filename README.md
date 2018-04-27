# cocoapods-tdfire-binary

A description of cocoapods-tdfire-binary.

## Installation

    $ gem install cocoapods-tdfire-binary
    
    
## TODO

1. 拥有 Subspec 的组件二进制依赖方式
2. 本地 Lint 二进制

## Usage

```

Usage:

    $ pod binary COMMAND

      2Dfire 二进制工具库，提供打包、lint、推送、拉取、发布等命令

Commands:

    + lint      对本地二进制进行 Lint
    + package   二进制打包
    + publish   正式发布二进制组件
    + pull      下载二进制 zip 包
    + push      推送二进制 zip 包

```

### For .gitignore

```
...

*.framework
*.zip
```

> For Podfile

```
...
plugin 'cocoapods-tdfire-binary'

tdfire_use_binary!
tdfire_use_source_pods ['AFNetworking']

use_frameworks!

...

```

### For podspec

> 目前只支持 iOS 平台 （插件内部也会进行限制）


```
...

tdfire_source_configurator = lambda do |s|
    # source configuration
    # s.source_files = 'PodA/Classes/**/*'
    # s.resource_bundles = {
    #   'PodA' => ['PodA/Assets/*']
    # }
end

unless %w[tdfire_set_binary_download_configurations tdfire_source tdfire_binary].reduce(true) { |r, m| s.respond_to?(m) & r }
    
  tdfire_source_configurator.call s
else
  s.tdfire_source tdfire_source_configurator
  s.tdfire_binary tdfire_source_configurator
  s.tdfire_set_binary_download_configurations
end

```

- tdfire_source_proc
  - 配置源码依赖

- tdfire_binary
  - 配置二进制依赖，其中 `vendored_framework` 、`source_files`、`public_header_files` 内部设置成如下路径
    
  ```
  s.vendored_framework = "#{s.name}.framework"
  #
  # 这两句 framework 不需要，cocoapods-packager 插件生成的 framework 中， Headers 是一个软连接 ，所以即使设置了也不生效
  # 这样就需要使用者都以 < > 的形式引用头文件了，而且需要是 umbrella 头文件，否则会出现警告 
  # s.source_files = "#{s.name}.framework/Headers/*"
  # s.public_header_files = "#{s.name}.framework/Headers/*"
  ```
  - 提取 subspec 中的依赖、frameworks、 libraries、 weak_frameworks，至二进制组件对应属性中
  - 在组件源码依赖有 subspec 的情况下，插件会在二进制依赖时，动态创建 default subspec `TdfireBinary`，以及源码依赖时的 subspec ，并且让后者的所有 subspec 依赖 `TdfireBinary`
  - 由于此方案对二进制中的 subspec 并**不做区分**，统一打包成一个二进制文件，所以如果在使用二进制依赖时，依赖了 subspec ，插件还是会去下载完整的二进制文件，并且从最终生成的结果看，目录中只有 `TdfireBinary` subspec
  - 此插件不支持嵌套 subspec 场景，如
  
  ```ruby
  Pod::Spec.new do |s|
    s.name = 'Root'
    s.subspec 'Level_1' do |sp|
      sp.subspec 'Level_2' do |ssp|
      end
    end
  end
  ``` 
   
- tdfire_set_binary_download_configurations
  - 强制设置 static_framework 为 true，规避使用 use_frameworks! 时，动态库依赖链（动态库依赖静态库问题）、影响启动时间问题
  - 设置 preserve_paths，让 cache 保留源码、资源、二进制全部文件
    - preserve_paths 由组件，子组件的源码、资源路径，以及 Framework 路径组成
  - 设置下载 prepare_command，未发布组件将会略过这一步骤

### For Lib Env

> Warning: 在发布二进制组件前，走二进制依赖流程，无法下载到对应 framework


- Env Key
  - tdfire_use_binary
    - 使用二进制依赖，确认值 1
  - tdfire_unpublished_pods 
    - 未发布的组件，用 `|` 隔开 (如 PodA|PodB， 一般只有一个，即当前开发组件)，设置后对应组件走源码依赖流程。
    - 二进制 lint 时，无法通过 Podfile 的 plugin 获取当前的 development pod （即当前开发组件） ，在发布对应二进制版本前，走二进制依赖流程，是下不到对应二进制版本的，所以需要自己设置当前开发组件名，对这一部分进行源码依赖。
  - tdfire_force_use_source
    - 强制使用源码依赖，确认值 1
    - 源码 lint 、未发布二进制组件前 CI 中 pod install / update （优先级比 Podfile 中的设置高） 时可使用 
  - tdfire_force_use_binary
    - 强制使用二进制依赖，确认值 1
    - 基本无用，在验证当前版本是否有对应二进制版本时可使用
  

例子：

```
env tdfire_use_binary=1 tdfire_unpublished_pods=PodA pod lib lint xxxx
env tdfire_force_use_source=1 pod install
```