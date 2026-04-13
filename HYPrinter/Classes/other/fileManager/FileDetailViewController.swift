//
//  FileDetailViewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/13.
//

import UIKit
import PDFKit


final class FileDetailViewController: BaseViewController {
    
    // MARK: - Public
    
    var pdfURL: URL?
    
    // MARK: - Private UI
    
    private lazy var actionPrintButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "printer_action"), for: .normal)
        button.addTarget(self, action: #selector(didTapPrintButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var pdfContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString:"#ECEFF7")
        return view
    }()
    
    private lazy var documentView: PDFView = {
        let view = PDFView()
        view.backgroundColor = UIColor(hexString:"#ECEFF7") ?? .white
        view.displayDirection = .vertical
        view.displayMode = .singlePageContinuous
        view.autoScales = true
        view.displaysPageBreaks = true
        view.usePageViewController(false)
        return view
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupSubviews()
        setupLayouts()
        loadPDFIfNeeded()
    }
}

// MARK: - Setup
private extension FileDetailViewController {
    
    func setupAppearance() {
        title = "详情"
        view.backgroundColor = UIColor(hexString:"#ECEFF7")
        topBar.backgroundColor = kmainColor
    }
    
    func setupSubviews() {
        topBar.addSubview(actionPrintButton)
        view.addSubview(pdfContainerView)
        pdfContainerView.addSubview(documentView)
    }
    
    func setupLayouts() {
        actionPrintButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-10)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        pdfContainerView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview().inset(10)
        }
        
        documentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Actions
private extension FileDetailViewController {
    
    @objc func didTapPrintButton() {
        startPrintFlow()
    }
}

// MARK: - Business
private extension FileDetailViewController {
    
    func loadPDFIfNeeded() {
        guard let fileURL = pdfURL else { return }
        
        guard let pdfDocument = PDFDocument(url: fileURL) else {
            print("❗️PDF 加载失败: \(fileURL)")
            return
        }
        
        documentView.document = pdfDocument
    }
    
    func startPrintFlow() {
        guard let fileURL = pdfURL else { return }
        
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = appName
        
        printController.printInfo = printInfo
        printController.printingItem = fileURL
        printController.present(animated: true, completionHandler: nil)
    }
}
