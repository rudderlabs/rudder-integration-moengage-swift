source 'https://github.com/CocoaPods/Specs.git'
workspace 'RudderMoEngage.xcworkspace'
use_frameworks!
inhibit_all_warnings!
platform :ios, '13.0'

def shared_pods
    pod 'Rudder', '~> 2.0.0'
end

target 'RudderMoEngage' do
    project 'RudderMoEngage.xcodeproj'
    shared_pods
    pod 'MoEngage-iOS-SDK', '~> 6.1.0'
end

target 'SampleAppObjC' do
    project 'Examples/SampleAppObjC/SampleAppObjC.xcodeproj'
    shared_pods
    pod 'RudderMoEngage', :path => '.'
end

target 'SampleAppSwift' do
    project 'Examples/SampleAppSwift/SampleAppSwift.xcodeproj'
    shared_pods
    pod 'RudderMoEngage', :path => '.'
end
