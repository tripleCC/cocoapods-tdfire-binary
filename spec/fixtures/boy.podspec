Pod::Spec.new do |s|
  s.name             = "boy"
  s.version          = "1.0.0"
  s.author           = { "boy" => "boy.@next.door" }
  s.summary          = "🙈🙉🙊"
  s.description      = "boy next door"
  s.homepage         = "http://httpbin.org/html"
  s.source           = { :git => "http://boy.next/door.git", :tag => s.version.to_s }
  s.license          = 'MIT'

  s.public_header_files   = 'boy.h'
  s.source_files   = 'boy.{h,m}'
end
