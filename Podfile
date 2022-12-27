platform :ios, '16.0'
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
