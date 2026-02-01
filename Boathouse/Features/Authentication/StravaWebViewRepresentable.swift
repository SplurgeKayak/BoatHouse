import SwiftUI
import WebKit

/// WebView representable for Strava OAuth web flow
struct StravaWebViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: StravaOAuthViewModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator

        if let url = viewModel.authorizationURL {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let viewModel: StravaOAuthViewModel

        init(viewModel: StravaOAuthViewModel) {
            self.viewModel = viewModel
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

            // Check if this is our redirect URI
            if url.absoluteString.starts(with: StravaConfig.redirectURI) {
                decisionHandler(.cancel)
                Task { @MainActor in
                    await viewModel.handleOAuthCallback(url: url)
                }
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Handle navigation errors
            print("WebView navigation error: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            // Handle provisional navigation errors
            print("WebView provisional navigation error: \(error.localizedDescription)")
        }
    }
}
