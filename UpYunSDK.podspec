Pod::Spec.new do |s|

  s.name = "UpYunSDK"
  s.version = "2.0"
  s.license = {:type=>"MIT", :file=>"LICENSE"}
  s.summary = "UpYunSDK"
  s.homepage = "https://github.com/nickcheng/UpYunSDK/"
  s.authors = {
    "nickcheng" => "n@nickcheng.com"
  }
  s.source = {
    :git => "https://github.com/nickcheng/UpYunSDK.git",
    :tag => "#{s.version}"
  }
  s.platform = :ios, "6.0"
  s.source_files = "UpYun"
  s.public_header_files = "UpYun/*.h"
  s.dependency 'AFNetworking', '~> 2.3'
  s.requires_arc = true

end