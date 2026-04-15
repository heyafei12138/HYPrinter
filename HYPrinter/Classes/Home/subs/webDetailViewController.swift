//
//  webDetailViewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/13.
//

import UIKit
import WebKit

final class webDetailViewController: BaseViewController, UITextFieldDelegate {
    
    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let addressContainerView = UIView()
    private let addressIconView = UIImageView()
    private let urlTextField = UITextField()
    private let stopButton = UIButton(type: .system)
    private let printButton = UIButton(type: .custom)
    
    private var progressObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        loadDefaultPage()
    }
    
    deinit {
        progressObservation?.invalidate()
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        title = "网页"
        view.backgroundColor = .white
        topBar.barBackgroundColor = .white
        
        setupAddressBar()
        setupPrintButton()
        setupWebView()
        setupProgressView()
    }
}

// MARK: - UI
private extension webDetailViewController {
    
    func setupAddressBar() {
        addressContainerView.backgroundColor = UIColor(hexString: "#ECEFF7") ?? UIColor.systemGray6
        addressContainerView.layer.cornerRadius = 12
        addressContainerView.layer.masksToBounds = true
        
        addressIconView.image = UIImage(named: "search_ic")
        addressIconView.tintColor = UIColor(hexString: "#7B8492") ?? .gray
        addressIconView.contentMode = .scaleAspectFit
        
        urlTextField.delegate = self
        urlTextField.placeholder = "输入网址或关键词"
        urlTextField.autocapitalizationType = .none
        urlTextField.autocorrectionType = .no
        urlTextField.clearButtonMode = .never
        urlTextField.keyboardType = .URL
        urlTextField.returnKeyType = .go
        urlTextField.textColor = .black
        urlTextField.font = .systemFont(ofSize: 15, weight: .medium)
        
        stopButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        stopButton.tintColor = UIColor(hexString: "#8A94A6") ?? .gray
        stopButton.addTarget(self, action: #selector(handleStopButtonTap), for: .touchUpInside)
        
        view.addSubview(addressContainerView)
        addressContainerView.addSubview(addressIconView)
        addressContainerView.addSubview(urlTextField)
        addressContainerView.addSubview(stopButton)
        
        addressContainerView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(52)
        }
        
        addressIconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        stopButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        urlTextField.snp.makeConstraints { make in
            make.left.equalTo(addressIconView.snp.right).offset(8)
            make.right.equalTo(stopButton.snp.left).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
    }
    
    func setupPrintButton() {
        printButton.setImage(UIImage(named: "printer_action"), for: .normal)
        printButton.alpha = 0.35
        printButton.isEnabled = false
        printButton.addTarget(self, action: #selector(handlePrintButtonTap), for: .touchUpInside)
        
        topBar.addSubview(printButton)
        printButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(24)
        }
    }
    
    func setupWebView() {
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .onDrag
        
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(addressContainerView.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
        
        let topLineView = UIView()
        topLineView.backgroundColor = UIColor(hexString: "#D9DBE1") ?? UIColor.systemGray5
        view.addSubview(topLineView)
        topLineView.snp.makeConstraints { make in
            make.top.equalTo(webView)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    func setupProgressView() {
        progressView.trackTintColor = .clear
        progressView.progressTintColor = kmainColor 
        progressView.isHidden = true
        
        view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.top.equalTo(webView)
            make.left.right.equalToSuperview()
            make.height.equalTo(2)
        }
    }
}

// MARK: - Data
private extension webDetailViewController {
    
    func setupBindings() {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let self else { return }
            let progress = Float(change.newValue ?? 0)
            self.progressView.isHidden = progress >= 1.0
            self.progressView.setProgress(progress, animated: true)
        }
    }
    
    func loadDefaultPage() {
        guard let url = URL(string: "https://www.google.com") else { return }
        urlTextField.text = url.absoluteString
        webView.load(URLRequest(url: url))
    }
    
    func loadEnteredText() {
        guard let rawText = urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              rawText.isEmpty == false else {
            return
        }
        
        let targetURL: URL?
        if rawText.contains(" "),
           let encodedQuery = rawText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            targetURL = URL(string: "https://www.google.com/search?q=\(encodedQuery)")
        } else if rawText.contains(".") {
            let urlString = rawText.hasPrefix("http://") || rawText.hasPrefix("https://") ? rawText : "https://\(rawText)"
            targetURL = URL(string: urlString)
        } else if let encodedQuery = rawText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            targetURL = URL(string: "https://www.google.com/search?q=\(encodedQuery)")
        } else {
            targetURL = nil
        }
        
        guard let targetURL else { return }
        webView.load(URLRequest(url: targetURL))
    }
    
    func updatePrintButtonState(isEnabled: Bool) {
        printButton.isEnabled = isEnabled
        printButton.alpha = isEnabled ? 1.0 : 0.35
    }
    
    func createWebPagePDF(completion: @escaping (URL?) -> Void) {
        if #available(iOS 14.0, *) {
            webView.createPDF(configuration: WKPDFConfiguration()) { result in
                switch result {
                case .success(let data):
                    completion(self.persistPDFData(data))
                case .failure:
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func persistPDFData(_ data: Data) -> URL? {
        let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("pdfs", isDirectory: true)
        
        guard let directoryURL else { return nil }
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let fileName = "web_\(Int(Date().timeIntervalSince1970 * 1000)).pdf"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func presentPrintController(with fileURL: URL) {
        guard PointsManager.shared.consumePrintPoints(from: self) else { return }
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        let pageTitle = webView.title ?? webView.url?.absoluteString ?? "网页打印"
        printInfo.jobName = pageTitle
        printController.printInfo = printInfo
        printController.printingItem = fileURL
        let sub = webView.url?.host
        try? PrintHistoryStore.shared.saveFilePrint(
            category: .web,
            title: pageTitle,
            subtitle: sub,
            copyingFileAt: fileURL
        )
        printController.present(animated: true, completionHandler: nil)
    }
    
    func presentPrintErrorAlert() {
        let alert = UIAlertController(
            title: "打印失败",
            message: "当前网页暂时无法生成可打印内容，请稍后重试。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "知道了", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Actions
private extension webDetailViewController {
    
    @objc func handleStopButtonTap() {
        if webView.isLoading {
            webView.stopLoading()
            progressView.isHidden = true
            progressView.progress = 0
        } else {
            urlTextField.text = nil
        }
    }
    
    @objc func handlePrintButtonTap() {
        guard printButton.isEnabled else { return }
        createWebPagePDF { [weak self] fileURL in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let fileURL else {
                    self.presentPrintErrorAlert()
                    return
                }
                self.presentPrintController(with: fileURL)
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension webDetailViewController {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loadEnteredText()
        return true
    }
}

// MARK: - WKNavigationDelegate
extension webDetailViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
        progressView.progress = 0
        updatePrintButtonState(isEnabled: false)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        urlTextField.text = webView.url?.absoluteString
        progressView.setProgress(1, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.progressView.isHidden = true
        }
        updatePrintButtonState(isEnabled: true)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        updatePrintButtonState(isEnabled: false)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        updatePrintButtonState(isEnabled: false)
    }
}
