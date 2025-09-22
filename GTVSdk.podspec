Pod::Spec.new do |s|
    s.name             = 'GTVSdk'
    s.version          = '1.0.5'
    s.summary          = 'GTV SDK cho iOS'
    s.description      = <<-DESC
    SDK hỗ trợ login, notification, tracking và quảng cáo cho ứng dụng iOS.
    DESC
    s.homepage         = 'https://github.com/duynk96/gtv-sdk-ios'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'duynk96' => 'duynk.hit@gmail.com' }
    s.source           = { :git => 'https://github.com/duynk96/gtv-sdk-ios.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '15.0'
    s.swift_versions   = ['5.0', '5.5', '5.9']
    
    s.static_framework = true
    
    # Source code
    s.source_files = 'Sources/**/*.{swift,h,m}'
    
    # Resource bundle riêng cho SDK
    s.resource_bundles = {
        'GTVSdkResources' => ['Resources/**/*.{png,jpg,json,xib,storyboard}']
    }
     
    # Dependencies (Firebase sẽ tự thêm resource bundle của nó)
    s.dependency 'Firebase/Messaging', '~> 12.3.0'
    s.dependency 'Google-Mobile-Ads-SDK', '~> 12.11.0'
    s.dependency 'Adjust', '~> 5.4.4'
end
