# cocoapods-tdfire-binary

A description of cocoapods-tdfire-binary.

## Installation

    $ gem install cocoapods-tdfire-binary

## Usage

> For .gitignore

```
...

*.framework
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

> For podspec

```
...

tdfire_source_proc = Proc.new do
    # source configuration
end

unless %w[tdfire_set_binary_download_configurations_at_last tdfire_source tdfire_binary].reduce(true) { |r, m| s.respond_to?(m) & r }
    
  tdfire_source_proc.call
else
  s.tdfire_source &tdfire_source_proc
  
  s.tdfire_binary do 
    s.vendored_framework = "#{s.name}.framework"
    s.source_files = "#{s.name}.framework/Headers/*"
    s.public_header_files = "#{s.name}.framework/Headers/*"

    # binary configuration
  end
  
  # s.tdfire_set_binary_download_configurations_at_last(download_url)
  s.tdfire_set_binary_download_configurations_at_last
end

```
