platform :ios, '17.0'
use_frameworks!

# ignore all warnings from all pods
# inhibit_all_warnings!

target 'PinchPad' do
  pod 'SwiftyJSON'
  pod 'SwiftyUserDefaults'
  pod 'Alamofire'
  pod 'SwiftLint'
  pod 'Swifter', git: 'https://github.com/mattdonnelly/Swifter.git'
  pod 'TMTumblrSDK', git: 'https://github.com/rofreg/TMTumblrSDK.git'
  pod 'RealmSwift'
  pod 'Locksmith'
  pod 'YYImage'
  pod 'FLEX', :configurations => ['Debug']
  pod 'MastodonKit'
end

plugin 'cocoapods-keys', {
  :project => 'PinchPad',
  :keys => [
    'TwitterConsumerKey',
    'TwitterConsumerSecret',
    'TumblrConsumerKey',
    'TumblrConsumerSecret',
    'MastodonBaseUrl',
    'MastodonAccessToken',
  ]
}

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      end
    end
  end
end
