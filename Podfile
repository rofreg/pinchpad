platform :ios, '15.0'
use_frameworks!

# ignore all warnings from all pods
inhibit_all_warnings!

target 'PinchPad' do
  pod 'SwiftyJSON'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Firebase/Performance'
  pod 'SwiftyUserDefaults'
  pod 'Alamofire'
  pod 'SwiftLint'
  pod 'Swifter', git: 'https://github.com/mattdonnelly/Swifter.git'
  pod 'TMTumblrSDK', git: 'https://github.com/rofreg/TMTumblrSDK.git'
  pod 'RealmSwift'
  pod 'Locksmith'
  pod 'YYImage'
  pod 'FLEX', :configurations => ['Debug']
end

plugin 'cocoapods-keys', {
  :project => 'PinchPad',
  :keys => [
    'TwitterConsumerKey',
    'TwitterConsumerSecret',
    'TumblrConsumerKey',
    'TumblrConsumerSecret'
  ]
}

# Silence warnings about iOS 8 no longer being supported
# https://github.com/CocoaPods/CocoaPods/issues/9884
post_install do |pi|
   pi.pods_project.targets.each do |t|
       t.build_configurations.each do |bc|
           bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
       end
   end
end
