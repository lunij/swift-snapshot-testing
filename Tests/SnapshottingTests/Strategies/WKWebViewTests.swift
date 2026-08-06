import Foundation
import Snapshotting
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(WebKit)
import WebKit
#endif

#if canImport(UIKit)
import UIKit.UIView
#endif

@MainActor
struct WKWebViewTests {
  #if os(iOS) || os(macOS)
  @Test func `web view`() async throws {
    let webView = WKWebView()
    webView.load(.init(url: .htmlFixture))
    await expectSnapshot(
      of: webView,
      as: .image(
        precision: 0.98,
        perceptualPrecision: 0.95,
        scale: 1,
        size: .init(width: 800, height: 600)
      )
    )
  }

  @Test func `web view with manipulating navigation delegate`() async throws {
    final class ManipulatingWKWebViewNavigationDelegate: NSObject, WKNavigationDelegate {
      func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // The fixture's `#banner` CSS makes the injected element stand out in the snapshot.
        webView.evaluateJavaScript(
          """
          const banner = document.createElement("div");
          banner.id = "banner";
          banner.textContent = "The navigation delegate has manipulated the DOM after the page finished loading.";
          document.body.appendChild(banner);
          """
        )
      }
    }
    let manipulatingWKWebViewNavigationDelegate = ManipulatingWKWebViewNavigationDelegate()
    let webView = WKWebView()
    webView.navigationDelegate = manipulatingWKWebViewNavigationDelegate
    webView.load(.init(url: .htmlFixture))
    await expectSnapshot(
      of: webView,
      as: .image(
        precision: 0.98,
        perceptualPrecision: 0.95,
        scale: 1,
        size: .init(width: 800, height: 600)
      )
    )
    _ = manipulatingWKWebViewNavigationDelegate
  }

  @Test func `web view with cancelling navigation delegate`() async throws {
    final class CancellingWKWebViewNavigationDelegate: NSObject, WKNavigationDelegate {
      func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
      ) {
        decisionHandler(.cancel)
      }
    }
    let cancellingWKWebViewNavigationDelegate = CancellingWKWebViewNavigationDelegate()
    let webView = WKWebView()
    webView.navigationDelegate = cancellingWKWebViewNavigationDelegate
    webView.load(.init(url: .htmlFixture))
    await expectSnapshot(
      of: webView,
      as: .image(size: .init(width: 800, height: 600))
    )
    _ = cancellingWKWebViewNavigationDelegate
  }
  #endif

  #if os(iOS)
  @Test func `embedded web view`() async throws {
    let label = UILabel()
    label.text = "Hello, Blob!"

    let webView = WKWebView()
    webView.load(.init(url: .htmlFixture))
    webView.isHidden = true

    let stackView = UIStackView(arrangedSubviews: [label, webView])
    stackView.axis = .vertical

    await expectSnapshot(
      of: stackView,
      as: .image(precision: 0.99, perceptualPrecision: 0.99, size: .init(width: 800, height: 600))
    )
  }
  #endif
}

private extension URL {
  static var htmlFixture: URL {
    URL(filePath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appending(path: "__Fixtures__/fixture.html")
  }
}
