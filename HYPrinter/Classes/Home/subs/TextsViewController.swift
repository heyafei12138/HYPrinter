//
//  TextsViewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/13.
//

import UIKit
import WebKit
import RZRichTextView

final class TextsViewController: BaseViewController, UITextViewDelegate {
    
    private let richTextViewModel: RZRichTextViewModel = {
        let model = RZRichTextViewModel()
        model.defaultColor = .black
        model.spaceRule = .removeHeadAndEnd
        model.inputItems = [
            .init(type: .tableStyle, image: RZRichImage.imageWith("ol"), highlight: RZRichImage.imageWith("ul")),
            .init(type: .paragraph, image: RZRichImage.imageWith("p_left"), highlight: RZRichImage.imageWith("p_left")),
            .init(type: .link, image: RZRichImage.imageWith("link"), highlight: RZRichImage.imageWith("link"))
        ]
        return model
    }()
    
    private lazy var textView: RZRichTextView = {
        // RZRichTextView 初始化时需要有效 width，后续再由 Auto Layout 接管尺寸
        let initialWidth = max(UIScreen.main.bounds.width - 32, 1)
        let view = RZRichTextView(
            frame: CGRect(x: 0, y: 0, width: initialWidth, height: 220),
            viewModel: richTextViewModel
        )
        view.backgroundColor = .white
        
        view.textColor = .black
        view.font = .systemFont(ofSize: 16)
        view.tintColor = kmainColor
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.textContainerInset = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)
        return view
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入或粘贴要打印的文本内容"
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor(hexString: "#A0A7B4") ?? .systemGray3
        label.numberOfLines = 2
        return label
    }()
    
    private let printButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "printer_action"), for: .normal)
        button.alpha = 0.35
        button.isEnabled = false
        return button
    }()
    
    private var hiddenWebView: WKWebView?
    private var webViewPrintDelegate: TextPDFWebViewDelegate?
    private var renderTimeoutWorkItem: DispatchWorkItem?
    private var keyboardObserverTokens: [NSObjectProtocol] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "文本"
        setupKeyboardObservers()
    }
    
    deinit {
        cleanupHiddenWebView()
        keyboardObserverTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        view.backgroundColor = kBgColor
        topBar.barBackgroundColor = .white
        
        topBar.addSubview(printButton)
        view.addSubview(textView)
        textView.addSubview(placeholderLabel)
        
        printButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(24)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(19)
            make.right.lessThanOrEqualToSuperview().inset(19)
        }
        
        textView.delegate = self
        printButton.addTarget(self, action: #selector(handlePrintButtonTap), for: .touchUpInside)
    }
}

// MARK: - UITextViewDelegate
extension TextsViewController {
    
    func textViewDidChange(_ textView: UITextView) {
        let hasText = hasPrintableContent()
        placeholderLabel.isHidden = hasText
        updatePrintButton(isEnabled: hasText)
    }
    
    func hasPrintableContent() -> Bool {
        let html = self.textView.code2html().trimmingCharacters(in: .whitespacesAndNewlines)
        return html.isEmpty == false
    }
}

// MARK: - Keyboard
private extension TextsViewController {
    
    func setupKeyboardObservers() {
        let willChange = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification)
        }
        
        let willHide = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateTextViewBottomInset(16)
        }
        
        keyboardObserverTokens = [willChange, willHide]
    }
    
    func handleKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrameInView.minY)
        let bottomInset = overlap > 0 ? overlap + 12 : 16
        updateTextViewBottomInset(bottomInset)
    }
    
    func updateTextViewBottomInset(_ inset: CGFloat) {
        textView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(inset)
        }
        view.layoutIfNeeded()
    }
}

// MARK: - Print
private extension TextsViewController {
    
    @objc func handlePrintButtonTap() {
        let bodyHTML = textView.code2html().trimmingCharacters(in: .whitespacesAndNewlines)
        guard bodyHTML.isEmpty == false else { return }
        
        let html = buildHTMLDocument(with: bodyHTML)
        generatePDFFromHTML(html) { [weak self] pdfURL in
            DispatchQueue.main.async {
                guard let self, let pdfURL else {
                    self?.presentPrintErrorAlert()
                    return
                }
                self.presentPrintController(with: pdfURL)
            }
        }
    }
    
    func updatePrintButton(isEnabled: Bool) {
        printButton.isEnabled = isEnabled
        printButton.alpha = isEnabled ? 1.0 : 0.35
    }
    
    func buildHTMLDocument(with bodyHTML: String) -> String {
        return """
        <!doctype html>
        <html>
        <head>
          <meta name='viewport' content='width=device-width, initial-scale=1.0'>
          <style>
            body {
              font-family: -apple-system, "PingFang SC", "Helvetica Neue", Arial, sans-serif;
              color: #191919;
              margin: 24px;
              font-size: 16px;
              line-height: 1.6;
            }
          </style>
        </head>
        <body>
          \(bodyHTML)
        </body>
        </html>
        """
    }
    
    func generatePDFFromHTML(_ html: String, completion: @escaping (URL?) -> Void) {
        cleanupHiddenWebView()
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595, height: 842), configuration: configuration)
        webView.isHidden = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        hiddenWebView = webView
        view.addSubview(webView)
        
        let delegate = TextPDFWebViewDelegate(
            onFinish: { [weak self] wkWebView in
                guard let self else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    guard #available(iOS 14.0, *) else {
                        self.cleanupHiddenWebView()
                        completion(nil)
                        return
                    }
                    
                    wkWebView.createPDF { result in
                        switch result {
                        case .success(let data):
                            completion(self.persistPDFData(data))
                        case .failure:
                            completion(nil)
                        }
                        self.cleanupHiddenWebView()
                    }
                }
            },
            onFail: { [weak self] _ in
                self?.cleanupHiddenWebView()
                completion(nil)
            }
        )
        
        webView.navigationDelegate = delegate
        webViewPrintDelegate = delegate
        webView.loadHTMLString(html, baseURL: nil)
        
        let timeoutWorkItem = DispatchWorkItem { [weak self, weak webView] in
            guard let self, let webView else { return }
            guard self.hiddenWebView === webView else { return }
            self.cleanupHiddenWebView()
            completion(nil)
        }
        renderTimeoutWorkItem = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: timeoutWorkItem)
    }
    
    func persistPDFData(_ data: Data) -> URL? {
        guard let docDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let pdfDirectory = docDirectory.appendingPathComponent("pdfs", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
            let fileName = "text_\(Int(Date().timeIntervalSince1970 * 1000)).pdf"
            let fileURL = pdfDirectory.appendingPathComponent(fileName)
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func presentPrintController(with fileURL: URL) {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "文本打印"
        printController.printInfo = printInfo
        printController.printingItem = fileURL
        try? PrintHistoryStore.shared.saveFilePrint(
            category: .text,
            title: "文本打印",
            subtitle: nil,
            copyingFileAt: fileURL
        )
        printController.present(animated: true, completionHandler: nil)
    }
    
    func presentPrintErrorAlert() {
        let alert = UIAlertController(
            title: "打印失败",
            message: "文本内容生成 PDF 失败，请稍后重试。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "知道了", style: .cancel))
        present(alert, animated: true)
    }
    
    func cleanupHiddenWebView() {
        renderTimeoutWorkItem?.cancel()
        renderTimeoutWorkItem = nil
        hiddenWebView?.stopLoading()
        hiddenWebView?.navigationDelegate = nil
        hiddenWebView?.removeFromSuperview()
        hiddenWebView = nil
        webViewPrintDelegate = nil
    }
}

private final class TextPDFWebViewDelegate: NSObject, WKNavigationDelegate {
    let onFinish: (WKWebView) -> Void
    let onFail: ((Error?) -> Void)?
    
    init(onFinish: @escaping (WKWebView) -> Void, onFail: ((Error?) -> Void)? = nil) {
        self.onFinish = onFinish
        self.onFail = onFail
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinish(webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onFail?(error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onFail?(error)
    }
}
