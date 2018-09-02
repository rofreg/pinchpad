# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
use_frameworks!

target 'PinchPad' do
  pod 'SwiftyJSON'
  pod 'Firebase/Core'
  pod 'Firebase/Crash'
  pod 'SwiftyUserDefaults'
  pod 'Alamofire'
  pod 'SwiftLint'
  pod 'TwitterKit'
  pod 'TMTumblrSDK', git: 'https://github.com/rofreg/TMTumblrSDK.git'
  pod 'ChromaColorPicker'
  pod 'RealmSwift'
  pod 'Locksmith'
  pod 'FLAnimatedImage'
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
