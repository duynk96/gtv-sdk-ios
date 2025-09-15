Pod::Spec.new do |s|
  s.name             = 'GTVSdk'
  s.version          = '1.0.0'
  s.summary          = 'GTV SDK cho iOS'
  s.description      = <<-DESC
    SDK hỗ trợ login, notification, tracking và quảng cáo cho ứng dụng iOS.
  DESC
  s.homepage         = 'https://github.com/duynk96/gtv-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'you@email.com' }
  s.source           = { :git => 'https://github.com/duynk96/gtv-sdk-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.static_framework = true

  # Source code
  s.source_files = 'Sources/**/*.{swift,h,m}'
  s.resources    = ['Resources/**/*.{xcassets,storyboard,xib}']

  # Dependencies
end
