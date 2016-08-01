Pod::Spec.new do |s|
  s.name     = 'apptentive-ios'
  s.module_name = 'Apptentive'
  s.version  = '3.2.1'
  s.license  = 'BSD'
  s.summary  = 'Apptentive Customer Communications SDK.'
  s.homepage = 'https://www.apptentive.com/'
  s.authors  = { 'Apptentive SDK Team' => 'sdks@apptentive.com' }
  s.source   = { :git => 'https://github.com/cdwat/apptentive-ios.git', :branch => "release/v3.2.1" }
  s.platform = :ios, '7.0'
  s.source_files   = 'ApptentiveConnect/source/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks     = 'AVFoundation', 'CoreData', 'CoreGraphics', 'Foundation', 'ImageIO', 'MobileCoreServices', 'QuartzCore', 'QuickLook', 'SystemConfiguration', 'UIKit'
  s.resources = 'ApptentiveConnect/resources/ApptentiveResources.bundle'
  s.weak_frameworks = 'StoreKit', 'CoreTelephony'
  s.prefix_header_contents = '#import "ApptentiveLog.h"'
  s.pod_target_xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS[config=Debug]" => "APPTENTIVE_LOGGING_LEVEL_DEBUG=1 APPTENTIVE_LOGGING_LEVEL_INFO=1 APPTENTIVE_LOGGING_LEVEL_WARNING=1 APPTENTIVE_LOGGING_LEVEL_ERROR=1",
  "GCC_PREPROCESSOR_DEFINITIONS[config=Release]" => "APPTENTIVE_LOGGING_LEVEL_ERROR=1" }
  s.public_header_files = 'ApptentiveConnect/source/Apptentive.h', 'ApptentiveConnect/source/ApptentiveStyleSheet.h'
end
