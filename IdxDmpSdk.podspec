#
# Be sure to run `pod lib lint IdxDmpSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IdxDmpSdk'
  s.version          = '2.3.2'
  s.summary          = 'IDX DMP iOS SDK'
  s.swift_version    = '5.7'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  IDX DMP Android SDK.
                       DESC

  s.homepage         = 'https://github.com/Brainway-LTD/idx-dmp-ios-sdk'
  s.readme           = 'https://github.com/Brainway-LTD/idx-dmp-ios-sdk/blob/main/README.md'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Brainway LTD' => 'brainway.co.il' }
  s.source           = { :git => 'https://github.com/Brainway-LTD/idx-dmp-ios-sdk.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'IdxDmpSdk/Classes/**/*'
  
  s.resources = "IdxDmpSdk/*.xcdatamodeld"
  # s.resource_bundles = {
  #   'IdxDmpSdk' => ['IdxDmpSdk/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'RealmSwift', '10.33.0'
end
