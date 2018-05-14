# cocoapods-tdfire-binary

<a href="https://travis-ci.org/tripleCC/cocoapods-tdfire-binary"><img src="https://img.shields.io/travis/tripleCC/cocoapods-tdfire-binary/master.svg"></a>

## 安装

    $ gem install cocoapods-tdfire-binary



## 插件目标



1. 通过提前将组件打包成 static-framework，减少主 App 打包时间

2. 提供源码和二进制依赖切换功能，方便开发调试

3. 尽量减少二进制化的工作量，以及对原发布流程的影响

4. 规避维护两套 podspec 和对应的 tag 

5. 体验尽量贴近 CocoaPods 原生 DSL

   

## 二进制化策略

### 二进制依赖方式



先了解下 podspec 的 source 字段，它接收一个 Hash，这个 Hash 对象指定了组件的储存地址。我们可以使用 keys 如下：



```ruby
:git => :tag, :branch, :commit, :submodules
:svn => :folder, :tag, :revision
:hg => :revision
:http => :flatten, :type, :sha256, :sha1
```

其中值得注意的有两个 key ，:git 不多说，这里说下 :http。 podspec 允许通过 HTTP 去下载组件代码压缩包，支持 zip, tgz, bz2, txz 和 tar 格式 ：



```ruby
spec.source = { :http => 'http://dev.wechatapp.com/download/sdk/WeChat_SDK_iOS_en.zip' }
```

结合上面对 source 字段的了解，可以解决一个比较关键的问题：二进制文件存在哪。这里的选择不多，“常规”无非两种：



1. 和源码一样，存在 tag 中
2. 起一个独立的二进制文件服务器

为什么说 “常规”，因为还有一种“非常规”的选择一一把源码和二进制一起打成 zip ，存在文件服务器上，通过指定 source 为 :http 去下载。当然，由于和 GitLab 本身的 tag 作用冲突，这种方式并不推荐。

接下来比较下“常规”的两种方式。

首先是实现起来较简单第一种，在把 framework 加入 tag 后，只需对 podspec 做如下更改：



```ruby
...
 s.source = { :git => 'git 地址',
                :tag => s.version.to_s }
if ENV['use_binary']
  s.vendored_frameworks = 'framework 的相对路径'
else
  s.source_files = '源码文件路径'
  s.public_header_files = '需要暴露的头文件路径'
end
...
```



但是考虑到后期产生过多的二进制版本，势必会导致 GitLab 库急剧变大，所以暂时不考虑第一种方式。

第二种，我们可以通过编写如下样式的 podspec 实现：



```ruby
...
if ENV['use_binary']
  spec.source = { :git => 'git url',
                :tag => s.version.to_s }
else
  spec.source = { :http => 'binary server url' }
end
...
```







## 插件说明



## 使用



```


Usage:

    $ pod binary COMMAND

      2Dfire 二进制工具库，提供打包、lint、推送、拉取、发布等命令

Commands:

    + assemble   执行二进制组件发布操作集合
    + delete     删除二进制版本
    + init       初始化二进制插件
    + lib        二进制模版库操作
    + lint       对本地二进制进行 Lint
    + list       查看所有二进制版本信息
    + package    二进制打包
    + publish    正式发布二进制组件
    + pull       下载二进制 zip 包
    + push       推送二进制 zip 包
    + search     查找二进制版本信息

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

- tdfire_source_configurator
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
