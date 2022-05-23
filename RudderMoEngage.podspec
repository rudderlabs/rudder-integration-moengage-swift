Pod::Spec.new do |s|
    s.name             = 'RudderMoEngage'
    s.version          = '1.0.0'
    s.summary          = 'Privacy and Security focused Segment-alternative. MoEngage Native SDK integration support.'
    s.description      = <<-DESC
    Rudder is a platform for collecting, storing and routing customer event data to dozens of tools. Rudder is open-source, can run in your cloud environment (AWS, GCP, Azure or even your data-centre) and provides a powerful transformation framework to process your event data on the fly.
    DESC
    s.homepage         = 'https://github.com/rudderlabs/rudder-moengage-ios'
    s.license          = { :type => "Apache", :file => "LICENSE" }
    s.author           = { 'RudderStack' => 'arnab@rudderlabs.com' }
    s.source           = { :git => 'https://github.com/rudderlabs/rudder-moengage-ios.git' , :tag => 'v#{s.version}'}
    
    s.ios.deployment_target = '13.0'

    s.pod_target_xcconfig = {
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    s.source_files = 'Sources/**/*{h,m,swift}'
    s.module_name = 'RudderMoEngage'
    s.swift_version = '5.3'

    s.dependency 'Rudder', '~> 2.0.0'
    s.dependency 'MoEngage-iOS-SDK', '~> 6.1.0'
end
