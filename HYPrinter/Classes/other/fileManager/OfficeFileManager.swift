//
//  OfficeFileManager.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/13.
//

import Foundation
import UIKit
import WebKit

final class OfficeFilePrintManager: NSObject {
    
    static let shared = OfficeFilePrintManager()
    
    private weak var presentingViewController: UIViewController?
    private var hiddenWebView: WKWebView?
    private var completionHandler: (() -> Void)?
    /// 用户发起打印时的原始文档 URL（用于写入打印历史）
    private var documentHistorySourceURL: URL?
    
    private override init() {
        super.init()
    }
    
    func startPrint(
        with fileURL: URL,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        self.presentingViewController = viewController
        self.completionHandler = completion
        self.documentHistorySourceURL = fileURL
        
        let fileKind = PrintableFileKind(url: fileURL)
        
        switch fileKind {
        case .directPrintable:
            presentNativePrintController(for: fileURL)
            
        case .plainText:
            renderTextFileInWebView(fileURL)
            
        case .webRenderable:
            renderGenericFileInWebView(fileURL)
            
        case .unsupported:
            documentHistorySourceURL = nil
            completion?()
        }
    }
}

// MARK: - File Type
private extension OfficeFilePrintManager {
    
    enum PrintableFileKind {
        case directPrintable
        case plainText
        case webRenderable
        case unsupported
        
        init(url: URL) {
            let ext = url.pathExtension.lowercased()
            
            switch ext {
            case "pdf", "png", "jpg", "jpeg":
                self = .directPrintable
                
            case "txt", "text", "log", "md", "csv":
                self = .plainText
                
            case "doc", "docx", "xls", "xlsx", "ppt", "pptx", "html", "htm", "rtf":
                self = .webRenderable
                
            default:
                self = .webRenderable
            }
        }
    }
}

// MARK: - WebView Load
private extension OfficeFilePrintManager {
    
    func renderGenericFileInWebView(_ fileURL: URL) {
        guard let containerVC = presentingViewController else {
            documentHistorySourceURL = nil
            completionHandler?()
            completionHandler = nil
            return
        }
        
        let webView = buildInvisibleWebView(in: containerVC.view)
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
    }
    
    func renderTextFileInWebView(_ fileURL: URL) {
        guard let containerVC = presentingViewController else {
            documentHistorySourceURL = nil
            completionHandler?()
            completionHandler = nil
            return
        }
        
        let content = readTextContent(from: fileURL)
        let htmlString = wrapTextAsHTML(content)
        
        let webView = buildInvisibleWebView(in: containerVC.view)
        webView.loadHTMLString(htmlString, baseURL: fileURL.deletingLastPathComponent())
    }
    
    @discardableResult
    func buildInvisibleWebView(in superView: UIView) -> WKWebView {
        clearWebPreviewIfNeeded()
        
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: superView.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.isHidden = true
        
        superView.addSubview(webView)
        hiddenWebView = webView
        return webView
    }
}

// MARK: - Text Convert
private extension OfficeFilePrintManager {
    
    func readTextContent(from fileURL: URL) -> String {
        if let utf8Text = try? String(contentsOf: fileURL, encoding: .utf8) {
            return utf8Text
        }
        if let defaultText = try? String(contentsOf: fileURL) {
            return defaultText
        }
        return ""
    }
    
    func wrapTextAsHTML(_ rawText: String) -> String {
        let escapedText = escapeHTML(rawText)
        
        return """
        <!doctype html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    background: #FFFFFF;
                    color: #222222;
                    font-family: -apple-system, BlinkMacSystemFont, Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                }
                .content {
                    padding: 16px;
                }
                pre {
                    margin: 0;
                    white-space: pre-wrap;
                    word-break: break-word;
                }
            </style>
        </head>
        <body>
            <div class="content">
                <pre>\(escapedText)</pre>
            </div>
        </body>
        </html>
        """
    }
    
    func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

// MARK: - Print
private extension OfficeFilePrintManager {
    
    func presentNativePrintController(for fileURL: URL) {
        guard let pvc = presentingViewController,
              PointsManager.shared.consumePrintPoints(from: pvc) else {
            documentHistorySourceURL = nil
            completionHandler?()
            completionHandler = nil
            return
        }
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = fileURL.lastPathComponent
        
        printController.printInfo = printInfo
        printController.printingItem = fileURL

        try? PrintHistoryStore.shared.saveFilePrint(
            category: .document,
            title: fileURL.lastPathComponent,
            subtitle: nil,
            copyingFileAt: fileURL
        )
        
        printController.present(animated: true) { [weak self] _, _, _ in
            guard let self else { return }
            self.documentHistorySourceURL = nil
            self.completionHandler?()
            self.completionHandler = nil
        }
    }
    
    func presentWebViewPrintController(using webView: WKWebView) {
        guard let pvc = presentingViewController,
              PointsManager.shared.consumePrintPoints(from: pvc) else {
            documentHistorySourceURL = nil
            clearWebPreviewIfNeeded()
            completionHandler?()
            completionHandler = nil
            return
        }
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = webView.url?.lastPathComponent ?? "Document"
        
        printController.printInfo = printInfo
        printController.printFormatter = webView.viewPrintFormatter()

        if let src = documentHistorySourceURL {
            try? PrintHistoryStore.shared.saveFilePrint(
                category: .document,
                title: src.lastPathComponent,
                subtitle: nil,
                copyingFileAt: src
            )
        }
        documentHistorySourceURL = nil
        
        printController.present(animated: true) { [weak self] _, _, _ in
            guard let self else { return }
            self.completionHandler?()
            self.completionHandler = nil
            self.clearWebPreviewIfNeeded()
        }
    }
}

// MARK: - Cleanup
private extension OfficeFilePrintManager {
    
    func clearWebPreviewIfNeeded() {
        hiddenWebView?.stopLoading()
        hiddenWebView?.navigationDelegate = nil
        hiddenWebView?.removeFromSuperview()
        hiddenWebView = nil
    }
}
extension OfficeFilePrintManager: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        presentWebViewPrintController(using: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        clearWebPreviewIfNeeded()
        documentHistorySourceURL = nil
        completionHandler?()
        completionHandler = nil
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        clearWebPreviewIfNeeded()
        documentHistorySourceURL = nil
        completionHandler?()
        completionHandler = nil
    }
}
