# QBWebViewControllerSDK

> WebViewController for QuBao

## 目录
* [功能简介](#sdk-功能简介)
* [导入方法](#sdk-导入方法)
* [使用方法](#sdk-使用方法)

#sdk-功能简介

本SDK是用Swift编写的一个webviewController库,只需简单传入URL便可打开网页，可自定义进度条颜色，接入美洽客服，并提供方法可注册与JS交互，默认已提供（获取APP信息，获取相册，导航栏添加关闭按钮，获取定位）功能供JS调用。


#sdk-导入方法

##使用CocoaPods导入(强烈推荐):

在Podfile中添加：

```
use_frameworks!
platform :ios, '8.0'
pod 'QBWebViewControllerSDK','~> 1.1.6'
```



#sdk-使用方法

## swift项目

在使用前需要

```
import QBWebViewControllerSDK
```

```swift
//在AppDelegate.swift 注册App
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    QBWebViewControllerSDK.registerApp()
    return true
}

//关闭服务
func applicationDidEnterBackground(_ application: UIApplication) {
    QBWebViewControllerSDK.closeSerivce()
}

//开启服务
func applicationWillEnterForeground(_ application: UIApplication) {
    QBWebViewControllerSDK.openService()
}

//开启推送
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    QBWebViewControllerSDK.registerDeviceToken(deviceToken)
}

```

```swift

//使用时仅需传入URL即可

let web = QBWebViewController(URL(string: "https://www.baidu.com")!)

//注册与JS交互的方法
web.registerJSMessageName("methodName") { (params, respCallback) in

}

self.navigationController?.pushViewController(web, animated: true)

```

**注意：**
* 由于本SDK提供了相册，麦克风，定位等功能，在使用前需在Info.plist文件中添加配置：

```
<key>NSCameraUsageDescription</key>
<string>配置相机权限</string>
<key>NSLocationUsageDescription</key>
<string>配置位置权限</string>
<key>NSMicrophoneUsageDescription</key>
<string>配置麦克风权限</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>配置相册权限</string>
```



