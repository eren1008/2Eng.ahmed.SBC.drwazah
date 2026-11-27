import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var loader: UIActivityIndicatorView!
    private let appURL = URL(string: "https://engahmedsbcdrwazah.vercel.app")!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0)

        let contentController = WKUserContentController()
        contentController.add(self, name: "iosPrint")
        contentController.add(self, name: "iosShareCSV")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.websiteDataStore = .default()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.bounces = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        loader = UIActivityIndicatorView(style: .large)
        loader.color = .white
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.hidesWhenStopped = true
        view.addSubview(loader)

        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        loadPortal()
    }

    private func loadPortal() {
        loader.startAnimating()
        var request = URLRequest(url: appURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20
        webView.load(request)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loader.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loader.stopAnimating()
        showOfflineScreen(message: error.localizedDescription)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loader.stopAnimating()
        showOfflineScreen(message: error.localizedDescription)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let scheme = (url.scheme ?? "").lowercased()
        if scheme == "mailto" || scheme == "tel" || url.host == "wa.me" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return nil
    }

    private func showOfflineScreen(message: String) {
        let html = """
        <!DOCTYPE html>
        <html lang="ar" dir="rtl">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center;
                 background:#0f172a; color:#f8fafc; font-family:-apple-system,Tahoma,sans-serif; padding:24px; text-align:center; }
          .box { max-width:380px; background:#1e293b; border:1px solid #334155; border-radius:16px; padding:24px; }
          h2 { margin:0 0 10px; font-size:19px; color:#38bdf8; }
          p { margin:0 0 18px; font-size:14px; color:#cbd5e1; line-height:1.6; }
          button { background:#0284c7; color:#fff; border:none; border-radius:10px; padding:12px 24px;
                   font-size:15px; font-weight:700; cursor:pointer; width:100%; }
        </style>
        </head>
        <body>
          <div class="box">
            <h2>تعذّر الاتصال ببوابة DRWAZAH SBC</h2>
            <p>يتطلب الدخول للتطبيق اتصالاً بالإنترنت للتحقق من صلاحية حسابك على الخادم المحمي.</p>
            <button onclick="window.location.href='https://engahmedsbcdrwazah.vercel.app'">إعادة المحاولة</button>
          </div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "iosPrint" {
            let dict = message.body as? [String: Any]
            let jobName = (dict?["title"] as? String) ?? "DRWAZAH SBC Report"
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.outputType = .general
            printInfo.jobName = jobName

            let printController = UIPrintInteractionController.shared
            printController.printInfo = printInfo
            printController.printFormatter = webView.viewPrintFormatter()
            printController.present(animated: true, completionHandler: nil)
        } else if message.name == "iosShareCSV" {
            guard let dict = message.body as? [String: Any],
                  let filename = dict["filename"] as? String,
                  let content = dict["content"] as? String else { return }

            let safeName = filename.replacingOccurrences(of: "/", with: "_")
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
            do {
                try content.write(to: tmpURL, atomically: true, encoding: .utf8)
                let activityVC = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
                if let pop = activityVC.popoverPresentationController {
                    pop.sourceView = self.view
                    pop.sourceRect = CGRect(x: self.view.bounds.midX, y: 80, width: 0, height: 0)
                }
                present(activityVC, animated: true, completion: nil)
            } catch {
                print("CSV export error: \(error)")
            }
        }
    }
}
