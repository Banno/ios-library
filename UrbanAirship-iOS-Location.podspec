Pod::Spec.new do |s|
   s.version                 = "11.0.0"
   s.name                    = "UrbanAirship-iOS-Location"
   s.summary                 = "Urban Airship iOS Location"

   s.documentation_url       = "http://docs.urbanairship.com/platform/ios.html"
   s.homepage                = "https://www.urbanairship.com"
   s.author                  = { "Urban Airship" => "support@urbanairship.com" }

   s.license                 = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
   s.source                  = { :git => "https://github.com/urbanairship/ios-library.git", :tag => s.version.to_s }

   s.module_name             = "AirshipLocationKit"
   s.ios.deployment_target   = "10.0"
   s.requires_arc            = true

   s.source_files            = 'AirshipLocationKit/AirshipLocationKit/*.{h,m}'
   s.private_header_files    = 'AirshipLocationKit/AirshipLocationKit/*+Internal*.h'

   s.frameworks              = 'Foundation', 'CoreLocation'
   s.dependency              "UrbanAirship-iOS-SDK", "11.0.0"
end
