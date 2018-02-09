//
//  WebViewController.swift
//

import UIKit
import WebKit
import MBProgressHUD
import CPEData

open class WebViewController: UIViewController {

    fileprivate struct Constants {
        static let ScriptMessageHandlerName = "microHTMLMessageHandler"
        static let ScriptMessageAppVisible = "AppVisible"
        static let ScriptMessageAppShutdown = "AppShutdown"

        static let HeaderButtonWidth: CGFloat = (DeviceType.IS_IPAD ? 125 : 100)
        static let HeaderButtonHeight: CGFloat = (DeviceType.IS_IPAD ? 90 : 50)
        static let HeaderIconPadding: CGFloat = (DeviceType.IS_IPAD ? 30 : 15)
    }

    private var url: URL!
    private var webView: WKWebView!
    public var hud: MBProgressHUD?
    public var shouldDisplayFullScreen = true
    
    // MARK: Initialization
    convenience public init(url: URL, title: String? = nil) {
        self.init()
        
        self.url = url
        self.title = title
        
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true), let deviceIdentifier = DeviceType.identifier {
            let deviceModelParam = "iphoneModel=\(deviceIdentifier)"
            if let query = components.query {
                components.query = "\(query)&\(deviceModelParam)"
            } else {
                components.query = deviceModelParam
            }

            if let newUrl = components.url {
                self.url = newUrl
            }
        }
    }

    // MARK: View Lifecycle
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black
        self.navigationController?.isNavigationBarHidden = shouldDisplayFullScreen

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        configuration.userContentController.add(self, name: Constants.ScriptMessageHandlerName)
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 9.0, *) {
            configuration.requiresUserActionForMediaPlayback = false
        } else {
            configuration.mediaPlaybackRequiresUserAction = false
        }

        webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        self.view.addSubview(webView)

        // Disable caching for now
        if #available(iOS 9.0, *) {
            if let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]) as? Set<String> {
                let date = Date(timeIntervalSince1970: 0)
                WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date, completionHandler: { })
            }
        } else if let libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, false).first {
            do {
                try FileManager.default.removeItem(atPath: "\(libraryPath)/Cookies")
            } catch {
                print("Error clearing cookies folder")
            }

            URLCache.shared.removeAllCachedResponses()
        }

        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))

        hud = MBProgressHUD.showAdded(to: webView, animated: true)
    }
    
    override open func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

    // MARK: Actions
    open func close() {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Constants.ScriptMessageHandlerName)
        webView.navigationDelegate = nil
        self.dismiss(animated: true, completion: nil)
    }

}

extension WebViewController: WKNavigationDelegate {

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame == nil {
            navigationAction.request.url?.promptLaunch(withMessage: String.localize("info.leaving_app.message_general"))
            return decisionHandler(.cancel)
        }
        
        decisionHandler(.allow)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hud?.hide(true)
    }

}

extension WebViewController: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == Constants.ScriptMessageHandlerName, let messageBody = message.body as? String {
            if messageBody == Constants.ScriptMessageAppVisible {

            } else if messageBody == Constants.ScriptMessageAppShutdown {
                close()
            }
        }
    }

}
