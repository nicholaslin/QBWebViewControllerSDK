
Pod::Spec.new do |s|


  s.name         = "QBWebViewControllerSDK"
  s.version      = "1.0.0"
  s.summary      = "just for QuBao."

  s.description  = "webViewController：提供通用接口用于H5调用"
		  
  s.homepage     = "https://github.com/nicholaslin/QBWebViewControllerSDK"
  s.license      = "MIT"

  s.author       = { "nicholaslin" => "990215314@qq.com" }
  s.platform     = :ios, "8.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/nicholaslin/QBWebViewControllerSDK.git", :tag => "#{s.version}"}

  s.frameworks    = "Foundation","Webkit","AVFoundation","MapKit","UIKit","AssetsLibrary","Photos"

  s.vendored_framework = "QBWebViewControllerSDK.framework"
  s.dependency "Meiqia", "~> 3.x"

end
