#
# Be sure to run `pod lib lint RAImagePicker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RAImagePicker'
  s.version          = '0.1.0'
  s.summary          = 'iMessage-like image picker for iOS +10.0'
  s.description      = <<-DESC
RAImagePicker is a protocol-oriented framework that provides custom features from the built-in Image Picker Edit.
                       DESC
  s.homepage         = 'https://github.com/rallahaseh/RAImagePicker'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rallahaseh' => 'rallahaseh@gmail.com' }
  s.source           = { :git => 'https://github.com/rallahaseh/RAImagePicker.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/rallahaseh'

  s.ios.deployment_target = '10.0'

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }

  s.source_files = 'RAImagePicker/Classes/**/*'

  s.resources    = ['RAImagePicker/Assets/*']

  s.frameworks = 'UIKit', 'Photos', 'Foundation', 'AVFoundation'

end
