import Foundation
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(WebKit)
import WebKit
#endif

#if canImport(UIKit)
import UIKit.UIView
#endif

@testable import SnapshotTesting

final class WKWebViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        diffTool = "ksdiff"
//        isRecording = true
    }

    override func tearDown() {
        isRecording = false
        super.tearDown()
    }

#if os(iOS) || os(macOS)
    func testWebView() throws {
        let webView = WKWebView()
        webView.load(.init(url: .htmlFixture))
        assertSnapshot(
            of: webView,
            as: .image(precision: 0.98, perceptualPrecision: 0.95, size: .init(width: 800, height: 600)),
            named: platform
        )
    }

    func testWebViewWithManipulatingNavigationDelegate() throws {
        final class ManipulatingWKWebViewNavigationDelegate: NSObject, WKNavigationDelegate {
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                webView.evaluateJavaScript("document.body.children[0].classList.remove(\"hero\")")  // Change layout
            }
        }
        let manipulatingWKWebViewNavigationDelegate = ManipulatingWKWebViewNavigationDelegate()
        let webView = WKWebView()
        webView.navigationDelegate = manipulatingWKWebViewNavigationDelegate
        webView.load(.init(url: .htmlFixture))
        assertSnapshot(
            of: webView,
            as: .image(precision: 0.98, perceptualPrecision: 0.95, size: .init(width: 800, height: 600)),
            named: platform
        )
        _ = manipulatingWKWebViewNavigationDelegate
    }

    func testWebViewWithCancellingNavigationDelegate() throws {
        final class CancellingWKWebViewNavigationDelegate: NSObject, WKNavigationDelegate {
            func webView(
                _ webView: WKWebView,
                decidePolicyFor navigationAction: WKNavigationAction,
                decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
            ) {
                decisionHandler(.cancel)
            }
        }
        let cancellingWKWebViewNavigationDelegate = CancellingWKWebViewNavigationDelegate()
        let webView = WKWebView()
        webView.navigationDelegate = cancellingWKWebViewNavigationDelegate
        webView.load(.init(url: .htmlFixture))
        assertSnapshot(
            of: webView,
            as: .image(size: .init(width: 800, height: 600)),
            named: platform
        )
        _ = cancellingWKWebViewNavigationDelegate
    }
#endif

#if os(iOS)
    func testEmbeddedWebView() throws {
        let label = UILabel()
        label.text = "Hello, Blob!"

        let webView = WKWebView()
        webView.load(.init(url: .htmlFixture))
        webView.isHidden = true

        let stackView = UIStackView(arrangedSubviews: [label, webView])
        stackView.axis = .vertical

        assertSnapshot(
            of: stackView,
            as: .image(precision: 0.99, perceptualPrecision: 0.99, size: .init(width: 800, height: 600)),
            named: platform
        )
    }
#endif
}

private extension URL {
    static var htmlFixture: URL {
        URL(fileURLWithPath: String(#file), isDirectory: false)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("__Fixtures__/pointfree.html")
    }
}
