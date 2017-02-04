//
//  QBWebViewController.swift
//  QBWebViewSDK
//
//  Created by 林子帆 on 2017/1/12.
//  Copyright © 2017年 林子帆. All rights reserved.
//

import Foundation
import WebKit
import AVFoundation
import MeiQiaSDK

extension UINavigationController:UINavigationBarDelegate {
    
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        
        if let webViewController = self.topViewController as? QBWebViewController {
            
            if webViewController.webView.canGoBack {
                webViewController.showCloseBarButtonItem()
                webViewController.webView.goBack()
                navigationBar.subviews.last?.alpha = 1
                return false
            }else {
                self.popViewController(animated: true)
                return true
            }
            
        }
        
        return true
        
    }
    
}

public class QBWebViewController: UIViewController,WKNavigationDelegate,WKScriptMessageHandler {
    
    public typealias QBJSMessageResp = ((_ respData:QBResp)->Void)
    public typealias QBJSMessageHandler = ((_ params:Any,_ respCallback:QBJSMessageResp)->Void)
    
    let JS_MESSAGE_HANDLE_NAME = "QBJSMessageHandler"
    
    let JS_GetAppInfo_Message_Name  = "Application_GetAppInfo"
    let JS_GetPicture_Message_Name  = "Application_GetPicture"
    let JS_ShowClose_Message_Name   = "Application_ShowClose"
    let JS_GetLocation_Message_Name = "Application_GetLocation"
    
    var url:URL!
    
    var webView:WKWebView!
    
    var defaultUserAgent:String {
        
        get{
            let wv = UIWebView()
            if let defaultUA = wv.stringByEvaluatingJavaScript(from: "navigator.userAgent") {
                return defaultUA
            }else {
                return ""
            }
        }
        
    }
    
    var progressView:UIProgressView?
    
    public var progressColor:UIColor?
    
    var hadRegisteredJSMsgHandlers:[String:QBJSMessageHandler] = [:]
    
    var isInjectedJSMsgHandlerNames:Bool = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(_ url: URL) {
        
        super.init(nibName: nil, bundle: nil)
        self.url = url
        
    }

    public override func viewDidLoad() {
        
        super.viewDidLoad()

        self.navigationItem.leftItemsSupplementBackButton = true
        webViewUseCustomUseAgent()
        
        self.view.backgroundColor = UIColor.white
        self.navigationItem.leftItemsSupplementBackButton = true
        self.automaticallyAdjustsScrollViewInsets = true
        
        registerGlobalJSMessageHandlers()
    
        configWebView()

        MQManager.initWithAppkey("6a33c4728df466019f6b62d2cb87f157") { (appid, error) in
            
            if error == nil {
                print("meiqia failer")
            }else {
                print("appid:\(appid!)")
            }
        }
//        QBLocationManager.shareInstance.requestAddress({ (address) in
//            
//        }) { (error) in
//        
//        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addProgressView()
        
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: JS_MESSAGE_HANDLE_NAME)
    }
    
    public func registerJSMessageName(_ name:String, handler:@escaping QBJSMessageHandler) {
        
        hadRegisteredJSMsgHandlers[name] = handler
        
    }
    
    //MARK:-----Setting UserInterface
    private func configWebView() {
        
        let userContentController = WKUserContentController()
        userContentController.add(self, name: JS_MESSAGE_HANDLE_NAME)
        
        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        
        if let jsFilePath = Bundle(for: QBWebViewController.self).path(forResource: "QBWebViewInjectJSCode", ofType: "js") {
            
            do {
                let jsString = try String(contentsOfFile: jsFilePath, encoding: .utf8)
                let js = WKUserScript(source: jsString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                config.userContentController.addUserScript(js)
            }catch  {
                print("Warning:js inject failed")
            }
        }else {
            
            fatalError("Warning:Cannot Find JS File")
        }
        
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) , configuration: config)
        
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.clear
        webView.allowsBackForwardNavigationGestures = true
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        webView.load(URLRequest(url: url))
        self.view.addSubview(webView)
        
    }
    
    private func addProgressView() {
        
        let navigationBarBounds = navigationController?.navigationBar.bounds
        guard navigationBarBounds != nil && navigationBarBounds?.width ?? 0 > 0 else {
            return
        }
        
        progressView = UIProgressView(frame: CGRect(x: 0, y: navigationBarBounds!.size.height, width: navigationBarBounds!.size.width, height: 3.0))
        progressView?.progressViewStyle = .bar
        progressView?.progressTintColor = progressColor ?? UIColor(red: 255.0/255, green: 126.0/255, blue: 15.0/255, alpha: 1)
        progressView?.progress = Float(webView.estimatedProgress)
        
        navigationController?.navigationBar.addSubview(progressView!)
        
    }

    
    private func registerGlobalJSMessageHandlers() {
        
        //registerJSMessageHandler_GetAppInfo()
        
        registerJSMessageHandler_TakePicture()
        
        registerJSMessageHandler_ShowClose()
    }
    
    private func registerJSMessageHandler_GetAppInfo() {
        
        registerJSMessageName(JS_GetAppInfo_Message_Name) { (params, respCallback) in
            
            var data:[String:Any]   = [:]
            data["deviceId"]        = ""
            data["deviceType"]      = 2
            data["version"]         = "1.9.0"
            data["channel"]         = 2001001
            data["system"]          = QBDeviceInfo.systemVersion
            data["model"]           = QBDeviceInfo.model
            data["isMiui"]          = 0
            
            respCallback(QBResp(status: .success, data: data, msg: nil))
  
        }

    }
    
    private func registerJSMessageHandler_TakePicture() {
        
        //JS_GetPicture_Message_Name
        registerJSMessageName(JS_GetAppInfo_Message_Name) { [weak self](params, respCallback) in
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let photographAction = UIAlertAction(title: "拍照", style: .default) { (action) in
                
                if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                    //CallbackFail:没有相机功能
                    return
                    
                }
                
                if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .denied || AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .restricted {
                    
                    let alertController = UIAlertController(title: "建议开启相机权限,以便程序能够正常运行,请点击[去设置]开启", message: nil, preferredStyle: .alert)
                    let settingAction = UIAlertAction(title: "去设置", style: .default, handler: { (action) in
                        
                        if let settingURL = URL(string: UIApplicationOpenSettingsURLString) {
                            UIApplication.shared.openURL(settingURL)
                        }
                        
                    })
                
                    let cancelAction = UIAlertAction(title: "暂不开启", style: .default, handler: { (action) in
                        
                        //CallbackFail:没有权限
                        return
                        
                    })
                    alertController.addAction(settingAction)
                    alertController.addAction(cancelAction)
                    self?.navigationController?.present(alertController, animated: true, completion: nil)
                    
                }
                
                let nav = QBTakePhotographNav()
                nav.allowsEditing = true
                nav.sourceType = .camera
                nav.delegate = nav
                let callback:((_ image:UIImage?)->Void) = { (image) in
                    
                }
                nav.completeCallback = callback
                self?.navigationController?.present(nav, animated: true, completion: nil)
                
            }
            
            let takePictureAction = UIAlertAction(title: "从相册选取", style: .default) { (action) in
                
                let nav = QBTakePictureNav.createTakePictureNav(completeCallback: { (image) in
                    
                    
                })
                
                self?.navigationController?.present(nav, animated: true, completion: nil)
            }
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action) in
                
                
                
            }
            
            alertController.addAction(photographAction)
            alertController.addAction(takePictureAction)
            alertController.addAction(cancelAction)
            
            self?.navigationController?.present(alertController, animated: true, completion: nil)
            
            
        }
        
    }
    
    private func registerJSMessageHandler_ShowClose() {
        
        registerJSMessageName(JS_ShowClose_Message_Name) { [weak self](params, respCallback) in
            
            if self?.webView.canGoBack ?? false {
                self?.showCloseBarButtonItem()
                respCallback(QBResp(status: .success))
            }
            
        }
        
    }
    
    private func registerJSMessageHandler_GetLocation() {
        
        registerJSMessageName(JS_GetLocation_Message_Name) { (params, respCallback) in
            
            QBLocationManager.shareInstance.requestAddress({ (address) in
                print("\(address.target.cityInfo.name)-\(address.target.cityInfo.code),\(address.target.provinceInfo.name)-\(address.target.provinceInfo.code),\(address.target.districtInfo.name)-\(address.target.districtInfo.code)")
                
            }, failed: { (error) in
                print(error)
            })
            
        }
        
    }
    
    
    func showCloseBarButtonItem() {
        
        let closeBtn = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(exitWebView))
        navigationItem.setLeftBarButtonItems([closeBtn], animated: false)
        
    }
    
    
    @objc private func exitWebView() {
        
        _ = navigationController?.popViewController(animated: true)
        
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            
            let progress = (change?[.newKey] as? Float ?? 0)
            progressView?.isHidden = false
            progressView?.setProgress(progress, animated: true)
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: { [weak self]() in
                    self?.progressView?.isHidden = true
                    self?.progressView?.setProgress(0.0, animated: false)
                })
            }
            
        }else if keyPath == "title" {
            self.title = change?[.newKey] as! String?
        }
    }
    
    //MARK:-----WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == JS_MESSAGE_HANDLE_NAME {
            
            handleJSMessageBody(message.body)
            
        }
    }
    
    
    //MARK:----- WKNavigationDelegate
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if !isInjectedJSMsgHandlerNames {
            injectJSMessageHandlerNames()
            isInjectedJSMsgHandlerNames = true
        }
        
        guard webView == self.webView else {
            decisionHandler(.cancel)
            return
        }
        
        guard let requestUrl = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        if requestUrl.scheme == "http" || requestUrl.scheme == "https" || requestUrl.description == "about:blank" {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            decisionHandler(.allow)
        }else {
            decisionHandler(.cancel)
        }

        
    }
    
    //MARK:-----通知JS当前Native可以处理的MessageName
    private func injectJSMessageHandlerNames() {
        
        var messageHandlerNames:[String] = []
        
        for jsMegName in hadRegisteredJSMsgHandlers.keys {
            messageHandlerNames.append(jsMegName)
        }

        var megHandlerNamesStr = ""
        do {
            let data = try JSONSerialization.data(withJSONObject: messageHandlerNames, options:JSONSerialization.WritingOptions.init(rawValue: 0))
            megHandlerNamesStr = String(data: data, encoding: .utf8) ?? ""
        } catch  {
            print("serialize failed")
        }
        
        let script = WKUserScript(source: "IOS.hasHandlerQueue = \(megHandlerNamesStr)", injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        
    }
    
    //MARK:-----处理JSMessage并回应
    private func handleJSMessageBody(_ body:Any) {
        
        guard let dic = body as? [String:Any] else {
            print("WARNING: JSMessage parse failed")
            return
        }
        
        guard let message = dic["message"] as? [String:Any] else {
            print("WARNING: JSMessage parse failed")
            return
        }
        
        let callbackId = message["callbackId"] as? String ?? ""
        let handlerName = message["handlerName"] as? String ?? ""
        let data = message["data"] ?? [:]
        
        guard let respHandler = hadRegisteredJSMsgHandlers[handlerName] else {
            print("WARNING: unimplement \(handlerName)'s callback")
            return
        }
        
        respHandler(data) { [weak self](resp) in
            
            let respStatus = resp.status
            let respData   = resp.data
            let respMsg    = resp.msg
            
            var respDic:[String:Any] = [:]
            
            if respMsg != nil {
                
                respDic = ["status":respStatus.rawValue, "data":respData, "msg":respMsg!]
                
            }else {
                
                respDic = ["status":respStatus.rawValue, "data":respData]
                
            }
            
            do {
                
                let respData = try JSONSerialization.data(withJSONObject: ["responseId":callbackId, "responseData":respDic], options: JSONSerialization.WritingOptions(rawValue: 0))
                if let respStr = String(data: respData, encoding: .utf8) {
                    
                    if Thread.current == .main {
                        
                        self?.webView.evaluateJavaScript("IOS._handleMessageFromNative('\(respStr)')", completionHandler: nil)
                    }else {
                        DispatchQueue.main.sync(execute: {[weak self]()in
                            self?.webView.evaluateJavaScript("IOS._handleMessageFromNative('\(respStr)')", completionHandler: nil)
                        })
                    }
                }
                
            }catch {}
            
        }
        
    }
    
    //MARK:-----设置自定义UA
    private func webViewUseCustomUseAgent() {
       
        if defaultUserAgent != "" {
            UserDefaults.standard.register(defaults: ["UserAgent":defaultUserAgent + " qubao100/1.9.0"])
        }
    }
    
    //MARK:-----恢复默认UA
    private func webViewUseDefaultUseAgent() {
        if defaultUserAgent != "" {
            UserDefaults.standard.register(defaults: ["UserAgent":defaultUserAgent])
        }
    }
    
    deinit {
        
        webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
        webView.removeObserver(self, forKeyPath: "title", context: nil)
        
        webViewUseDefaultUseAgent()
        
        print("QBWebViewController deinit")
        
    }
    

}
