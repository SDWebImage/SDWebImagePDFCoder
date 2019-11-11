#
# Be sure to run `pod lib lint SDWebImagePDFCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImagePDFCoder'
  s.version          = '0.3.0'
  s.summary          = 'A PDF coder plugin for SDWebImage, using built-in framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
SDWebImageSVGCoder is a SVG coder plugin for SDWebImage framework, which provide the image loading support for SVG using SVGKit SVG engine.
                       DESC

  s.homepage         = 'https://github.com/SDWebImage/SDWebImagePDFCoder'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DreamPiggy' => 'lizhuoli1126@126.com' }
  s.source           = { :git => 'https://github.com/SDWebImage/SDWebImagePDFCoder.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'

  s.source_files = 'SDWebImagePDFCoder/Classes/**/*', 'SDWebImagePDFCoder/Module/SDWebImagePDFCoder.h'
  s.module_map = 'SDWebImagePDFCoder/Module/SDWebImagePDFCoder.modulemap'
  
  s.dependency 'SDWebImage', '~> 5.0'
end
