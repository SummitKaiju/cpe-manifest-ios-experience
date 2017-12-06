Pod::Spec.new do |s|

  s.name                = 'CPEExperience'
  s.version             = '4.1.1'
  s.summary             = 'iOS User Experience for Cross-Platform Extras'
  s.license             = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.homepage            = 'https://github.com/warnerbros/cpe-manifest-ios-experience'
  s.author              = { 'Alec Ananian' => 'alec.ananian@warnerbros.com' }

  s.platform            = :ios, '8.0'

  s.dependency            'CPEData',            '~> 3.0'
  s.dependency            'google-cast-sdk',    '~> 3.0'
  s.dependency            'MBProgressHUD',      '~> 0.9'
  s.dependency            'SDWebImage',         '~> 4.0'
  s.dependency            'UAProgressView',     '~> 0.1'
  s.dependency            'ReachabilitySwift',  '~> 3.0'

  s.source              = { :git => 'https://github.com/warnerbros/cpe-manifest-ios-experience.git', :tag => s.version.to_s }
  s.source_files        = 'Source/**/*.swift', 'Source/*.swift'
  s.resource_bundles    = {
    'CPEExperience' => ['Source/**/*.{xcassets,storyboard,strings,xib,ttf}']
  }

  # GoogleMaps
  s.vendored_frameworks = 'Frameworks/*.framework'
  s.frameworks          = 'Accelerate', 'AVFoundation', 'CoreBluetooth', 'CoreData', 'CoreLocation', 'CoreText', 'GLKit', 'ImageIO', 'OpenGLES', 'QuartzCore', 'Security', 'SystemConfiguration', 'CoreGraphics'
  s.libraries           = 'icucore', 'c++', 'z'
  s.xcconfig            = { 'FRAMEWORK_SEARCH_PATHS' => File.join(File.dirname(__FILE__), 'Frameworks') }

end
