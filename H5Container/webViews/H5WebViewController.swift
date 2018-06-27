//
//  H5WebViewController.swift
//  SuperPicture
//
//  Created by lcy on 2018/6/11.
//  Copyright © 2018年 lcy. All rights reserved.
//

import UIKit
import SnapKit
import WebKit
import Alamofire
import MBProgressHUD
import LeanCloud



class H5WebViewController: UIViewController {
    
    var webView: WKWebView!
    
    var h5TabContainerView: H5TabView!
    
    var progressView: UIView!
    
//    var netManager = NetworkReachabilityManager(host: "https://www.baidu.com/")
    
    
    var isDisConnect = false //是否无网络
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        h5TabContainerView = Bundle.main.loadNibNamed("H5TabView", owner: nil, options: nil)?.first as! H5TabView
        self.view.addSubview(h5TabContainerView)
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaPlaybackRequiresUserAction = false

        webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        if #available(iOS 11, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        self.view.addSubview(webView)
        
        
        if #available(iOS 11, *) {
            h5TabContainerView.snp.makeConstraints { (make) in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                make.left.right.equalTo(self.view)
                make.height.equalTo(0)
            }
            webView.snp.makeConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.left.right.equalTo(self.view)
                make.bottom.equalTo(self.h5TabContainerView.snp.top)
            }
        } else {
            h5TabContainerView.snp.makeConstraints { (make) in
                make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
                make.left.right.equalTo(self.view)
                make.height.equalTo(0)
            }
            webView.snp.makeConstraints { (make) in
                make.top.equalTo(self.topLayoutGuide.snp.bottom)
                make.left.right.equalTo(self.view)
                make.bottom.equalTo(self.h5TabContainerView.snp.top)
            }
        }
        
        //进度条
        progressView = UIView()
        progressView.backgroundColor = UIColor.red
        self.view.addSubview(progressView)
        
        progressView.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.left.equalTo(self.view.safeAreaLayoutGuide)
                make.height.equalTo(2)
                make.width.equalTo(0)
            } else {
                make.top.equalTo(self.topLayoutGuide.snp.bottom)
                make.left.equalTo(self.view)
                make.height.equalTo(2)
                make.width.equalTo(0)
            }
        }
        
        
        lcy_buildTabView()
        
        lcy_fornet()
        
        lcy_listenNetwork()
        
        
    }
    
    func lcy_listenNetwork() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityChanged),
            name: NSNotification.Name.reachabilityChanged,
            object: nil
        )
        
    }
    
    @objc func reachabilityChanged(notification: NSNotification) {
        let ap = UIApplication.shared.delegate as! AppDelegate
        let reach = ap.reach
        if (reach?.isReachableViaWiFi())! || (reach?.isReachableViaWWAN())! {
            
                if self.isDisConnect {
                    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud.mode = .customView
                    hud.customView = UIImageView(image: UIImage(named: "Checkmark"))
                    hud.label.text = "恢复网络"
                    hud.hide(animated: true, afterDelay: 2.0)
                    self.isDisConnect = false
                }

        } else {
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                hud.mode = .customView
                hud.customView = UIImageView(image: UIImage(named: "noNet"))
                hud.label.text = "无网络"
                self.isDisConnect = true
                hud.hide(animated: true, afterDelay: 2.0)
        }
    }


    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func lcy_fornet() {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: false)
        let query = LCQuery(className: "Config")
        query.whereKey("appid", .equalTo("zuboll"))
        
        query.find({ (result) in
            hud.hide(animated: true)
            switch result {
            case .success(let objects):
                if let obj1 = objects.first {
                    let isS = obj1.get("show")?.boolValue
                    let u = obj1.get("url")?.stringValue
                    let secU = obj1.get("secUrl")?.stringValue
                    if isS! {
                        self.webView.load(URLRequest(url: URL(string: u!)!))
                        self.webView.scrollView.bounces = false
                        if #available(iOS 11, *) {
                            self.h5TabContainerView.snp.remakeConstraints { (make) in
                                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                                make.left.right.equalTo(self.view)
                                make.height.equalTo(50)
                            }
                        } else {
                            self.h5TabContainerView.snp.remakeConstraints { (make) in
                                make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
                                make.left.right.equalTo(self.view)
                                make.height.equalTo(50)
                            }
                        }

                    } else {
                        self.webView.load(URLRequest(url: URL(string: secU!)!))
                        self.webView.scrollView.bounces = false
                    }
                }
            case .failure(let error):
                print(error)
            }

        })
        
    }
    
    //按钮
    func lcy_buildTabView() {
        h5TabContainerView.homeBtn.addTarget(self, action: #selector(lcy_homeBtnClick), for: .touchUpInside)
        h5TabContainerView.backBtn.addTarget(self, action: #selector(lcy_backBtnClick), for: .touchUpInside)
        h5TabContainerView.goBtn.addTarget(self, action: #selector(lcy_goBtnClick), for: .touchUpInside)
        h5TabContainerView.refreshBtn.addTarget(self, action: #selector(lcy_refreshBtnClick), for: .touchUpInside)
        h5TabContainerView.clearBtn.addTarget(self, action: #selector(lcy_clearBtnClick), for: .touchUpInside)
        
    }
    
    @objc func lcy_homeBtnClick() {
        if let first = webView.backForwardList.backList.first {
            webView.go(to: first)
        }
        
    }
    @objc func lcy_backBtnClick() {
        if(webView.canGoBack) {
            webView.goBack()
        }
    }
    @objc func lcy_goBtnClick() {
        if(webView.canGoForward) {
            webView.goForward()
        }

    }
    @objc func lcy_refreshBtnClick() {
        webView.reload()
    }
    @objc func lcy_clearBtnClick() {
        lcy_ClearCache()
        let vc = UIAlertController(title: nil, message: "清除成功", preferredStyle: .alert)
        let action = UIAlertAction(title: "确定", style: .default, handler: nil)
        vc.addAction(action)
        self.present(vc, animated: true, completion: nil)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
//    -------------
    // MARK: - 清空缓存
    
    func lcy_ClearCache() {
        
        
        
        let dateFrom: Date = Date.init(timeIntervalSince1970: 0)
        
        
        
        if #available(iOS 9.0, *) {
            
            let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {
                
            }
        } else {
            
            let libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first
            let cookiesPath = libraryPath! + "/Cookies"
            try!FileManager.default.removeItem(atPath: cookiesPath)

        }
        
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let ov = object as? WKWebView,
            let keyPath = keyPath,
            let newValue = change?[.newKey] as? CGFloat {
            if newValue == 1.0 {
                UIView.animate(withDuration: 0.2, animations: {
                    self.progressView.snp.updateConstraints { (make) in
                        make.width.equalTo(0)
                    }
                }) { (bool) in
                    self.progressView.isHidden = true
                }
            } else {
                self.progressView.isHidden = false
                UIView.animate(withDuration: 0.2) {
                    self.progressView.snp.updateConstraints { (make) in
                        make.width.equalTo(UIScreen.main.bounds.width * newValue)
                    }
                }
            }
        }
        
    }
    
    
}

extension H5WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    //加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("")
    }
    //    网页弹框 --- 确认弹框
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController()
        let act1 = UIAlertAction(title: "确定", style: .default) { (action) in
            completionHandler(true)
        }
        let act2 = UIAlertAction(title: "取消", style: .default) { (action) in
            completionHandler(false)
        }
        alert.addAction(act1)
        alert.addAction(act2)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urlStr = navigationAction.request.url?.absoluteString
        if (urlStr?.hasPrefix("itms"))! || (urlStr?.hasPrefix("itunes.apple.com"))! {
            let url = URL(string: urlStr!)
            if UIApplication.shared.canOpenURL(url!) {
                let alertVC = UIAlertController(title: nil, message: "在App Store中打开?", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "取消", style: .default, handler: nil)
                let alertAction_sure = UIAlertAction(title: "打开", style: .default) { (action) in
                    UIApplication.shared.openURL(url!)
                }
                alertVC.addAction(alertAction)
                alertVC.addAction(alertAction_sure)
                self.present(alertVC, animated: true, completion: nil)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    //支持跨域下载， 连接APPstore啥的
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let targetF =  navigationAction.targetFrame {
            if targetF.isMainFrame {
                
            } else {
                webView.load(navigationAction.request)
            }
        } else {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

extension H5WebViewController: WKUIDelegate {
    
}
