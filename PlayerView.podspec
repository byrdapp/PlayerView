

Pod::Spec.new do |s|
  s.name             = "PlayerView"
  s.version          = "0.2.8"
  s.summary          = "A UIView for videos using AVPlayer with delegate"
  s.swift_version    = '4.2'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
                        This Library allows to set a video on a custom UIView by setting the callbacks on a delegate for easy use. this View implements the AVPlayer from AVFoundation
                       DESC

  s.homepage         = "https://github.com/byrdapp/PlayerView"
  s.license          = 'MIT'
  s.author           = { "David Alejandro" => "davidlondono9@gmail.com" }
  s.source           = { :git => "https://github.com/byrdapp/PlayerView.git", :tag => s.version }
  s.social_media_url = 'https://twitter.com/davidlondono'

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Sources/**/*'

end
