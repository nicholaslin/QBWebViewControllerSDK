
Pod::Spec.new do |s|


  s.name         = "QBWebViewControllerSDK"
  s.version      = "1.0.0"
  s.summary      = "just for QuBao."

  s.description  = webViewController：提供通用接口用于H5调用 
		  
  s.homepage     = "https://github.com/nicholaslin/QBWebViewControllerSDK"
  s.license      = "MIT"

  s.author       = { "nicholaslin" => "990215314@qq.com" }
  s.platform     = :ios, "8.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/nicholaslin/QBWebViewControllerSDK.git", :tag =>"1.0.1"}


  s.frameworks    = "Foundation","Webkit","AVFoundation","MapKit","UIKit","AssetsLibrary","Photos"

  s.vendored_framework = "QBWebViewControllerSDK.framework"
#s.resource_bundle = {'QBWebViewSDK' => 'Source/Vendor/QBTakePicture/*.{storyboard}'}
  #s.exclude_files = "Classes/Exclude"

#s.public_header_files = ["QBWebViewSDK/Sources/QBWebViewSDK.h"]


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
#s.resources = "Resources/*.{json,js}"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.


# s.pod_target_xcconfig = {'SWIFT_VERSION'=>'3'}

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
   s.dependency "Meiqia", "~> 3.x"

end
