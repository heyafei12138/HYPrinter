//
//  HomeVC.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import UIKit
import PhotosUI

class HomeVC: BaseViewController, UIDocumentPickerDelegate {
    
    var pageHeaderTitle: String = "HYPrinter" {
        didSet {
            titleLabel.text = pageHeaderTitle
        }
    }
    
    var onBannerTap: (() -> Void)?
    var onMoreModuleTap: ((HomeMoreModule) -> Void)?
    
    override var shouldHideNavigationBar: Bool {
        get { true }
        set { }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .black
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let pointsButton: UIButton = {
        let b = UIButton(type: .custom)
        b.layer.cornerRadius = 16
        b.layer.masksToBounds = true
        return b
    }()

    private var didPlaceFloatDefault = false

    private let floatCheckIn = HomeCheckInFloatingView()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    private let bannerView = HomeBannerView()
    private let sectionLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.text = "👋 Get Started"
        return label
    }()
    private let featureGridView = HomeFeatureGridView()
    private let moreModulesView = HomeMoreModulesSectionView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleAction()
        pointsButton.addTarget(self, action: #selector(onPointsButtonTap), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPointsButton), name: .pointsBalanceDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onFloatingCheckInShouldRestart), name: .homeFloatingCheckInShouldRestart, object: nil)
        floatCheckIn.onTapWhenUnlocked = { [weak self] in
            self?.openSignInFromHome()
        }
        refreshPointsButton()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func refreshPointsButton() {
        let v = PointsManager.shared.balance
        let img = UIImage(named: "get_revord_icon")
        
        pointsButton.setImage(img, for: .normal)
        pointsButton.setTitle(" \(v)", for: .normal)
        pointsButton.setTitleColor(UIColor.white, for: .normal)
        pointsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        pointsButton.backgroundColor = kmainColor
        
    }

    @objc private func onPointsButtonTap() {
        openPointsHistoryFromHome()
    }

    private func openPointsHistoryFromHome() {
        let vc = PointsHistoryViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openSignInFromHome() {
        let vc = SignInViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onFloatingCheckInShouldRestart() {
        floatCheckIn.restartCountdownAfterSignIn()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshPointsButton()
        floatCheckIn.resumeOrStartIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        floatCheckIn.pauseTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didPlaceFloatDefault, titleLabel.frame.maxY > 0 else { return }
        didPlaceFloatDefault = true
        let s = HomeCheckInFloatingView.diameter
        floatCheckIn.bounds = CGRect(x: 0, y: 0, width: s, height: s)
        let safe = view.safeAreaInsets
        let x = view.bounds.width - safe.right - 10 - s / 2
        let y = titleLabel.frame.maxY + 14 + s / 2
        floatCheckIn.center = CGPoint(x: x, y: y)
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        titleLabel.text = pageHeaderTitle
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        contentView.backgroundColor = .clear
        
        view.addSubview(titleLabel)
        view.addSubview(pointsButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(floatCheckIn)
        contentView.addSubview(stackView)
        
        stackView.addArrangedSubview(bannerView)
        stackView.addArrangedSubview(sectionLabel)
        stackView.addArrangedSubview(featureGridView)
        stackView.addArrangedSubview(moreModulesView)
        
        pointsButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).inset(12)
            make.height.equalTo(36)
            make.width.greaterThanOrEqualTo(88)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.left.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(pointsButton.snp.leading).offset(-8)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16))
        }
        
        bannerView.snp.makeConstraints { make in
            make.height.equalTo(196)
        }
        sectionLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        featureGridView.snp.makeConstraints { make in
            make.height.equalTo(176)
        }
        
        moreModulesView.snp.makeConstraints { make in
            make.height.equalTo(280)
        }

        floatCheckIn.translatesAutoresizingMaskIntoConstraints = true
        view.bringSubviewToFront(floatCheckIn)

        bannerView.onTap = { [weak self] in
            self?.onBannerTap?()
        }
    }
    func handleAction(){
        featureGridView.onTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case 0:
                selectImageAndPrint()
            case 1:
                selectFile()
            case 2:
                selectMaterial()
            default:
                break
            }
        }
        
        moreModulesView.onItemTap = { [weak self] module in
            self?.handleMoreModuleTap(module)
        }
    }
    
    func handleMoreModuleTap(_ module: HomeMoreModule) {
        if let onMoreModuleTap {
            onMoreModuleTap(module)
            return
        }
        
        switch module {
        case .text:
            let controller = TextsViewController()
            pushController(controller)
        case .web:
            let controller = webDetailViewController()
            pushController(controller)
        case .contact:
            let controller = contactViewController()
            pushController(controller)
        case .label:
            let controller = StickerViewController()
            pushController(controller)
        case .iCloud:
            selectFile()
        default:
            break
        }
    }
    func selectMaterial() {
        let vc = GreetingCardListViewController()
        pushController(vc)
    }

}
extension HomeVC: PHPickerViewControllerDelegate {
    
    @objc func selectImageAndPrint() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0 // 只允许选择一张图片
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - PHPicker Delegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard !results.isEmpty else { return }
            
            var selectedImages: [UIImage] = []
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    dispatchGroup.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                        if let image = reading as? UIImage, error == nil {
                            selectedImages.append(image)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            // 等待所有图片加载完成后再打印
            dispatchGroup.notify(queue: .main) { [weak self] in
                guard let self = self, !selectedImages.isEmpty else { return }
                self.presentPrintController(for: selectedImages)
            }
        }
        
        // MARK: - 打印逻辑
    func presentPrintController(for images: [UIImage]) {


        let vc = PhotoPreviewController(images: images)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)

    }
}

extension HomeVC{
    @objc private func selectFile() {
        let supportedTypes: [UTType] = [
            .pdf,
            .image, // 包含 jpg、png、heic 等常见图片
            .jpeg,
            .png,
            .spreadsheet, // Excel (.xls, .xlsx)
            .rtf,
            .presentation, // PPT
            .text,
            
            UTType("com.microsoft.word.doc")!,     // .doc
            UTType("org.openxmlformats.wordprocessingml.document")!, // .docx
            UTType("com.microsoft.excel.xls")!,    // .xls
            UTType("org.openxmlformats.spreadsheetml.sheet")! // .xlsx
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - UIDocumentPicker Delegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        //            selectedFileURL = url
        ensureFileAvailable(at: url) { localURL in
            guard let localURL = localURL else { return }

            OfficeFilePrintManager.shared.startPrint(with: localURL, from: self, completion: nil)
            /*
            if #available(iOS 16.0, *) {
//                let now = String.currentDateTime
                // 👇 获取 PDF 文件大小
                let pdfSize = localURL.formattedFileSize
                print("PDF size: \(pdfSize)")
                let rawName = localURL.lastPathComponent
                let decodedName: String
                if let data = rawName.data(using: .utf8) {
                    decodedName = String(data: data, encoding: .utf8) ?? rawName
                } else {
                    decodedName = rawName
                }
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let pdfsURL = documentsURL.appendingPathComponent("pdfs")
                try? FileManager.default.createDirectory(at: pdfsURL, withIntermediateDirectories: true)
                let destURL = pdfsURL.appendingPathComponent(localURL.lastPathComponent)
                try? FileManager.default.copyItem(at: localURL, to: destURL)
                let relativePath = "pdfs/" + localURL.lastPathComponent

//                DBManager.shared.insertFilePaths(name: decodedName, paths: [relativePath],size: pdfSize)
            } else {
                // Fallback on earlier versions
            }*/

        }
    }

    
    private func ensureFileAvailable(at url: URL, completion: @escaping (URL?) -> Void) {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        var isDir: ObjCBool = false
        let fm = FileManager.default
        
        // 如果文件存在，尝试复制到本地可访问位置
        if fm.fileExists(atPath: url.path, isDirectory: &isDir) {
            print("File already available locally: \(url.path)")
            
            // 如果路径包含 "File Provider Storage"，说明可能是云端容器（需复制）
            if url.path.contains("File Provider Storage") {
                let tempDir = fm.temporaryDirectory.appendingPathComponent("PrintableFiles", isDirectory: true)
                try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
                
                let localURL = tempDir.appendingPathComponent(url.lastPathComponent)
                
                do {
                    if fm.fileExists(atPath: localURL.path) {
                        try fm.removeItem(at: localURL)
                    }
                    try fm.copyItem(at: url, to: localURL)
                    print("✅ File copied into sandbox: \(localURL.path)")
                    completion(localURL)
                } catch {
                    print("❌ File copy failed: \(error.localizedDescription)")
                    completion(nil)
                }
            } else {
                // 普通路径，直接使用
                completion(url)
            }
            return
        }
        
        // iCloud 文件处理
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { newURL in
            if fm.fileExists(atPath: newURL.path) {
                completion(newURL)
            } else {
                do {
                    try fm.startDownloadingUbiquitousItem(at: newURL)
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                        if fm.fileExists(atPath: newURL.path) {
                            completion(newURL)
                        } else {
                            completion(nil)
                        }
                    }
                } catch {
                    print("❌ iCloud download failed: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
    
}
