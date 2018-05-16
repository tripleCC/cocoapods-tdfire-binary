

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





