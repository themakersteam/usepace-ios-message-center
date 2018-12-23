#
# Be sure to run `pod lib lint MessageCenter.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MessageCenter'
  s.version          = '0.1.21'
  s.summary          = 'MessageCenter is chatting SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
                       
  s.homepage         = 'https://github.com/UsePace/ios-message-center'
  s.swift_version     = '4.0'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cEliteDev' => 'iagilelite@gmail.com' }
  s.source           = { :git => 'https://github.com/UsePace/ios-message-center.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  s.source_files = 'MessageCenter/Classes/**/*'
  s.dependency 'SendBirdSDK'
  s.dependency 'AlamofireImage'
  s.dependency 'MGSwipeTableCell'
  s.dependency 'FLAnimatedImage', '~> 1.0'
  s.dependency 'NYTPhotoViewer', '~> 1.1.0'
  s.dependency 'TTTAttributedLabel'
  s.dependency 'CryptoSwift'
  s.dependency 'HTMLKit'
  s.dependency 'Toast', '~> 4.0.0'
   s.resource_bundles = {
     'MessageCenter' => ['MessageCenter/Assets/*.{storyboard,png,xib,lproj/*.strings}']
   }
#   s.resources = 'MessageCenter/Images/*.xcassets'
   #'MessageCenter/Localizable/*.lproj/*.strings'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
