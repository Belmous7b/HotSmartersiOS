# CocoaPods — adds the VLC media engine (MobileVLCKit) so Live TV can play
# MPEG-TS / HLS / any-codec IPTV streams that Apple's AVPlayer refuses.
# CI runs `xcodegen generate` first (creates the .xcodeproj), then `pod install`
# (creates HotSmartersiOS.xcworkspace), then builds the workspace.
platform :ios, '16.0'

target 'HotSmartersiOS' do
  use_frameworks!
  pod 'MobileVLCKit'
end

# Keep every pod target's deployment target >= the app's, and allow building
# without code signing on CI (Sideloadly re-signs the app + frameworks later).
post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
