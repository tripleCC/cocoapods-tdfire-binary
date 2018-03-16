# cocoapods-tdfire-binary

A description of cocoapods-tdfire-binary.

## Installation

    $ gem install cocoapods-tdfire-binary

## Usage

> For Podfile

```
...
plugin 'cocoapods-tdfire-binary'

tdfire_use_binary!
tdfire_use_source_pods 'AFNetworking'

use_frameworks!

...

tdfire_external_pods 'SDWebImage'

```

> For podspec

```
s.tdfire_source |s|
# source configuration
	...

end

s.tdfire_binary |s|
# binary configuration

	s.vendored_framework = "#{s.name}.framework"
  s.source_files = "#{s.name}.framework/Headers/*"
  s.public_header_files = "#{s.name}.framework/Headers/*"

  ...
end

s.tdfire_set_binary_download_configurations_at_last
```
