//
//  contactViewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/13.
//

import Contacts
import PDFKit
import UIKit
import WebKit

final class contactViewController: BaseViewController {
    
    private let contactStore = CNContactStore()
    
    private let previewContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#ECEFF7") ?? .systemGroupedBackground
        return view
    }()
    
    private let pdfView: PDFView = {
        let view = PDFView()
        view.backgroundColor = UIColor(hexString: "#ECEFF7") ?? .systemGroupedBackground
        view.displayDirection = .vertical
        view.displayMode = .singlePageContinuous
        view.autoScales = true
        view.displaysPageBreaks = true
        view.usePageViewController(false)
        return view
    }()
    
    private let stateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(hexString: "#6D7684") ?? .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reload", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.backgroundColor = kmainColor
        button.layer.cornerRadius = 22
        return button
    }()
    
    private let printButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "printer_action"), for: .normal)
        button.alpha = 0.35
        button.isEnabled = false
        return button
    }()
    
    private var pdfURL: URL?
    private var contacts: [CNContact] = []
    private var hiddenWebView: WKWebView?
    private var renderTimeoutWorkItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestContactsAndGeneratePDF()
    }
    
    deinit {
        cleanupHiddenWebView()
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        title = "Contacts"
        view.backgroundColor = UIColor(hexString: "#ECEFF7") ?? .systemGroupedBackground
        topBar.barBackgroundColor = .white
        
        topBar.addSubview(printButton)
        view.addSubview(previewContainerView)
        previewContainerView.addSubview(pdfView)
        previewContainerView.addSubview(stateLabel)
        previewContainerView.addSubview(retryButton)
        
        printButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(24)
        }
        
        previewContainerView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview().inset(10)
        }
        
        pdfView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(24)
        }
        
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(stateLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
        
        printButton.addTarget(self, action: #selector(handlePrintButtonTap), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(handleRetryButtonTap), for: .touchUpInside)
        
        applyState(.loading("Loading contacts..."))
    }
}

// MARK: - State
private extension contactViewController {
    
    enum ViewState {
        case loading(String)
        case preview
        case empty(String)
        case failed(String, showSettings: Bool)
    }
    
    func applyState(_ state: ViewState) {
        switch state {
        case .loading(let message):
            pdfView.isHidden = true
            stateLabel.isHidden = false
            retryButton.isHidden = true
            stateLabel.text = message
            updatePrintButton(isEnabled: false)
            
        case .preview:
            pdfView.isHidden = false
            stateLabel.isHidden = true
            retryButton.isHidden = true
            updatePrintButton(isEnabled: true)
            
        case .empty(let message):
            pdfView.isHidden = true
            stateLabel.isHidden = false
            retryButton.isHidden = false
            retryButton.setTitle("Reload", for: .normal)
            stateLabel.text = message
            updatePrintButton(isEnabled: false)
            
        case .failed(let message, let showSettings):
            pdfView.isHidden = true
            stateLabel.isHidden = false
            retryButton.isHidden = false
            retryButton.setTitle(showSettings ? "Settings" : "Retry", for: .normal)
            stateLabel.text = message
            updatePrintButton(isEnabled: false)
        }
    }
    
    func updatePrintButton(isEnabled: Bool) {
        printButton.isEnabled = isEnabled
        printButton.alpha = isEnabled ? 1.0 : 0.35
    }
}

// MARK: - Contacts
private extension contactViewController {
    
    func requestContactsAndGeneratePDF() {
        applyState(.loading("Loading contacts..."))
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            fetchContactsAndGeneratePDF()
            
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    granted ? self.fetchContactsAndGeneratePDF() : self.applyContactsDeniedState()
                }
            }
            
        case .denied, .restricted:
            applyContactsDeniedState()
            
        @unknown default:
            applyState(.failed("Contact permission status is abnormal. Please try again later.", showSettings: false))
        }
    }
    
    func fetchContactsAndGeneratePDF() {
        DispatchQueue.global(qos: .userInitiated).async {
            let keys: [CNKeyDescriptor] = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactOrganizationNameKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPostalAddressesKey as CNKeyDescriptor
            ]
            
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .userDefault
            
            var fetchedContacts: [CNContact] = []
            
            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    fetchedContacts.append(contact)
                }
                
                DispatchQueue.main.async {
                    self.contacts = fetchedContacts
                    guard fetchedContacts.isEmpty == false else {
                        self.applyState(.empty("No contacts are available for export."))
                        return
                    }
                    self.generatePDFPreview(with: fetchedContacts)
                }
            } catch {
                DispatchQueue.main.async {
                    self.applyState(.failed("Failed to read contacts. Please try again later.", showSettings: false))
                }
            }
        }
    }
    
    func applyContactsDeniedState() {
        applyState(.failed("Please enable Contacts permission in Settings before exporting.", showSettings: true))
    }
}

// MARK: - PDF
private extension contactViewController {
    
    func generatePDFPreview(with contacts: [CNContact]) {
        cleanupHiddenWebView()
        applyState(.loading("Generating contact preview..."))
        
        let html = buildHTML(with: contacts)
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595, height: 842), configuration: WKWebViewConfiguration())
        webView.isHidden = true
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        hiddenWebView = webView
        view.addSubview(webView)
        webView.loadHTMLString(html, baseURL: nil)
        
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.cleanupHiddenWebView()
            self.applyState(.failed("Contact preview generation timed out. Please try again.", showSettings: false))
        }
        renderTimeoutWorkItem = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0, execute: timeoutWorkItem)
    }
    
    func persistPDFData(_ data: Data) -> URL? {
        guard let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("pdfs", isDirectory: true) else {
            return nil
        }
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let fileURL = directoryURL.appendingPathComponent("contacts_\(Int(Date().timeIntervalSince1970 * 1000)).pdf")
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func showPDF(_ url: URL) {
        guard let document = PDFDocument(url: url) else {
            applyState(.failed("Failed to load contact PDF preview.", showSettings: false))
            return
        }
        
        pdfView.document = document
        applyState(.preview)
    }
    
    func buildHTML(with contacts: [CNContact]) -> String {
        let formatter = CNContactFormatter()
        
        let sections = contacts.map { contact in
            var blocks: [String] = []
            let fullName = formatter.string(from: contact)?.trimmed ?? ""
            if fullName.isEmpty == false {
                blocks.append("<h2>\(fullName.htmlEscaped)</h2>")
            }
            if contact.organizationName.isEmpty == false {
                blocks.append("<p>\(contact.organizationName.htmlEscaped)</p>")
            }
            if contact.phoneNumbers.isEmpty == false {
                let items = contact.phoneNumbers.map { "<li>\($0.value.stringValue.htmlEscaped)</li>" }.joined()
                blocks.append("<p><strong>Phone</strong></p><ul>\(items)</ul>")
            }
            if contact.emailAddresses.isEmpty == false {
                let items = contact.emailAddresses.map { "<li>\(String($0.value).htmlEscaped)</li>" }.joined()
                blocks.append("<p><strong>Email</strong></p><ul>\(items)</ul>")
            }
            if contact.postalAddresses.isEmpty == false {
                let items = contact.postalAddresses.map { address -> String in
                    let value = address.value
                    let composed = [value.street, value.city, value.state, value.postalCode, value.country]
                        .map(\.trimmed)
                        .filter { $0.isEmpty == false }
                        .joined(separator: ", ")
                    return "<li>\(composed.htmlEscaped)</li>"
                }.joined()
                blocks.append("<p><strong>Address</strong></p><ul>\(items)</ul>")
            }
            return "<section>\(blocks.joined())</section>"
        }.joined()
        
        return """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background: #FFFFFF;
              color: #191919;
              font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', Helvetica, Arial, sans-serif;
            }
            body {
              padding: 24px;
            }
            section {
              margin-bottom: 24px;
              page-break-inside: avoid;
              border-bottom: 1px solid #ECEFF7;
              padding-bottom: 16px;
            }
            h2 {
              margin: 0 0 8px 0;
              font-size: 18px;
              line-height: 1.4;
            }
            p {
              margin: 0 0 8px 0;
              font-size: 14px;
              line-height: 1.5;
            }
            ul {
              margin: 4px 0 12px 18px;
              padding: 0;
            }
            li {
              margin-bottom: 4px;
              font-size: 14px;
              line-height: 1.5;
              word-break: break-word;
            }
          </style>
        </head>
        <body>
          \(sections)
        </body>
        </html>
        """
    }
    
    func cleanupHiddenWebView() {
        renderTimeoutWorkItem?.cancel()
        renderTimeoutWorkItem = nil
        hiddenWebView?.stopLoading()
        hiddenWebView?.navigationDelegate = nil
        hiddenWebView?.removeFromSuperview()
        hiddenWebView = nil
    }
}

// MARK: - Actions
private extension contactViewController {
    
    @objc func handlePrintButtonTap() {
        guard let pdfURL else { return }
        guard PointsManager.shared.consumePrintPoints(from: self) else { return }

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "Contacts"
        controller.printInfo = info
        controller.printingItem = pdfURL
        try? PrintHistoryStore.shared.saveFilePrint(
            category: .contact,
            title: "Contacts Print",
            subtitle: nil,
            copyingFileAt: pdfURL
        )
        controller.present(animated: true, completionHandler: nil)
    }
    
    @objc func handleRetryButtonTap() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .denied, .restricted:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        default:
            requestContactsAndGeneratePDF()
        }
    }
}

// MARK: - WKNavigationDelegate
extension contactViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === hiddenWebView else { return }
        
        if #available(iOS 14.0, *) {
            webView.createPDF(configuration: WKPDFConfiguration()) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.cleanupHiddenWebView()
                    
                    switch result {
                    case .success(let data):
                        guard let url = self.persistPDFData(data) else {
                            self.applyState(.failed("Failed to save contact PDF.", showSettings: false))
                            return
                        }
                        self.pdfURL = url
                        self.showPDF(url)
                    case .failure:
                        self.applyState(.failed("Failed to generate contact PDF. Please try again.", showSettings: false))
                    }
                }
            }
        } else {
            cleanupHiddenWebView()
            applyState(.failed("The current iOS version does not support contact PDF generation.", showSettings: false))
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard webView === hiddenWebView else { return }
        cleanupHiddenWebView()
        applyState(.failed("Failed to load contact preview. Please try again.", showSettings: false))
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard webView === hiddenWebView else { return }
        cleanupHiddenWebView()
        applyState(.failed("Failed to load contact preview. Please try again.", showSettings: false))
    }
}

private extension String {
    
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
