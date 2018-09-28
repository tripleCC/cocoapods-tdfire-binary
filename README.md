# cocoapods-tdfire-binary

<a href="https://travis-ci.org/tripleCC/cocoapods-tdfire-binary"><img src="https://img.shields.io/travis/tripleCC/cocoapods-tdfire-binary/master.svg"></a>

插件分为 pod binary 命令， 二进制 SDL 两部分。

辅助组件二进制组件化的 CocoaPods 插件，适合希望解决以下业务场景的开发者：



1. 通过提前将组件打包成 static-framework，减少主 App 打包时间

2. 提供源码和二进制依赖切换功能，方便开发调试

3. 尽量减少二进制化的工作量，以及对原发布流程的影响

4. 规避维护两套 podspec 和对应的 tag 

5. 体验尽量贴近 CocoaPods 原生 DSL

## 安装

    $ gem install cocoapods-tdfire-binary



## 使用



此插件需要结合二进制服务器使用，其中主要接口如下：



```

```





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



## pod binary 命令

以下命令都可以追加 `--verbose` 查看执行的详细流程。

### pod binary init

初始化二进制插件，执行命令后，展示以下交互界面：

```
开始设置二进制化初始信息.
所有的信息都会保存在 binary_config.yaml 文件中.
你可以在 /Users/songruiwang/.cocoapods/binary_config.yml 目录下手动添加编辑该文件.
/Users/songruiwang/.cocoapods/binary_config.yml 文件包含配置信息如下：

---
server_host: 输入二进制服务器地址 (比如 http://xxxxx:8080)
repo_url: 输入私有源 Git 地址 (比如 https://github.com/tripleCC/PrivateSpecRepo.git)
template_url: 输入 pod 模版 Git 地址 (比如 https://github.com/CocoaPods/pod-template.git)


输入二进制服务器地址 (比如 http://xxxxx:8080)
 > 
```

使用者需要提供以下信息：

- server_host
  - 二进制服务器地址，供插件的二进制功能部分使用
- repo_url
  - 私有源 Git 地址，通过插件 lint 、发布等功能时使用
- template_url 
  - pod 模版 Git 地址，通过插件创建模版时使用

如果存在旧值，直接键入回车键表示采用旧值。

```
输入二进制服务器地址 (比如 http://xxxxx:8080)
旧值：http:xxxxxx
 >
http:xxxxxx
```

### pod binary lib create 

> pod binary lib create NAME

创建二进制模版库。内部为 `pod lib create --template-url=xxx` 的一层简单包装，其中的 `--template-url` 对应上一小节 `binary_config.yaml` 中的 `template_url` 配置项。

推荐在模版库中预置项目组开发常用信息，如添加 CI/CD 配置文件，在 Podfile 中设置业务组件常见底层依赖等。

### pod binary lib import

> pod binary lib import [PATH]

根据 podspec 生成与组件同名伞头文件。在没有指定 PATH 的情况下，默认在执行命令目录生成伞头文件。当指定目录伞头文件已存在时，会执行替换操作。


### pod binary list 

查看所有二进制版本信息。和 `pod list` 输出格式一致。

### pod binary lint

> pod binary lint --sources=xxxx --binary-first

对本地组件进行 lint。内部为 `pod lib lint` 的封装。

- `--binary-first`
  - 在没有指定 `--binary-first` 的情况下，和 `pod lib lint` 效果一致，指定之后，插件会优先采用**依赖组件的二进制版本**加快 lint ，lint 组件自身依然会采用源码。如果依赖的某些组件没有二进制版本，插件会对这些组件采用源码依赖。
- `--sources`
  - 私有源地址，在没有指定 `--sources` 的情况下，使用的 sources 为 `binary_config.yaml` 中的 `repo_url` 配置。

### pod binary search

> pod binary search NAME

查找二进制版本信息。和 `pod search` 输出格式一致。

### pod binary package

> pod binary package --spec-sources=xxxx --subspecs=xxxx --use-carthage --clean --binary-first

将源码打包成二进制，并压缩成 zip 包。其中二进制为静态 framework 封装格式。

- `--spec-sources`
  - 私有源地址，在没有指定的情况下，使用的 sources 为 `binary_config.yaml` 中的 `repo_url` 配置。
- `--subspecs`
  - 打包目标子组件，默认会打包所有组件
- `--use-carthage`
  - 使用 carthage 进行打包，三方库提供 carthage 的优先。没有指定的话，使用 `cocoapods-packager` 插件进行打包。
- `--binary-first`
  - 打包时，依赖组件优先采用二进制版本，加快编译。如果依赖的某些组件没有二进制版本，插件会对这些组件采用源码依赖。
- `--clean`
  - 执行成功后，删除 zip 文件外的所有生成文件

### pod binary pull

> pod binary pull NAME VERSION

下载二进制 zip 包。

### pod binary push

> pod binary push [PATH] --name=xxxx --version=xxxx --commit=xxxx

将二进制 zip 包推送至二进制服务器。 PATH 为 zip 包所在地址。

- `--name`
  - 推送二进制的组件名，没指定时，采用当前 podspec 中的组件名
- `--versio`
  - 推送二进制的版本号，没指定时，采用当前 podspec 中的版本号
- `--commit`
  - 推送二进制的版本日志，没指定时，采用当前分支最新 commit sha

### pod binary publish 

> pod binary publish [NAME.podspec] --commit=xxxx --sources=xxxx --binary-first

正式发布二进制组件版本。内部为 `pod repo push` 的封装。

- `--commit`
  - 发布的 commit 信息
- `--binary-first`
  - 发布时，依赖组件优先采用二进制版本，加快编译。如果依赖的某些组件没有二进制版本，插件会对这些组件采用源码依赖。
- `--sources`
  - 私有源地址，在没有指定的情况下，使用的 sources 为 `binary_config.yaml` 中的 `repo_url` 配置。

### pod binary delete

> pod binary delete NAME VERSION

将二进制从服务器中删除。

