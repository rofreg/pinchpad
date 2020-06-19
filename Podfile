# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
use_frameworks!

target 'PinchPad' do
  pod 'SwiftyJSON'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Firebase/Analytics'
  pod 'Firebase/Performance'
  pod 'SwiftyUserDefaults'
  pod 'Alamofire'
  pod 'SwiftLint'
  pod 'Swifter', git: 'https://github.com/mattdonnelly/Swifter.git'
  pod 'TMTumblrSDK', git: 'https://github.com/rofreg/TMTumblrSDK.git'
  pod 'RealmSwift'
  pod 'Locksmith'
  pod 'FLAnimatedImage'
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
