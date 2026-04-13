//
//  HomeVC.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import UIKit
import PhotosUI

class HomeVC: BaseViewController {
    
    var pageHeaderTitle: String = "掌上打印" {
        didSet {
            titleLabel.text = pageHeaderTitle
        }
    }
    
    var onBannerTap: (() -> Void)?
    
    override var shouldHideNavigationBar: Bool {
        get { true }
        set { }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .black
        return label
    }()
    
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
        label.text = "👋 立即开始"
        return label
    }()
    private let featureGridView = HomeFeatureGridView()
    private let moreModulesView = HomeMoreModulesSectionView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        titleLabel.text = pageHeaderTitle
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        contentView.backgroundColor = .clear
        
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        stackView.addArrangedSubview(bannerView)
        stackView.addArrangedSubview(sectionLabel)
        stackView.addArrangedSubview(featureGridView)
        stackView.addArrangedSubview(moreModulesView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(20)
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
            default:
                break
            }
        }
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
        
//        let printInfo = UIPrintInfo(dictionary: nil)
//        printInfo.outputType = .photo
//        printInfo.jobName = "Printer".localized()
//
//        let printController = UIPrintInteractionController.shared
//        printController.printInfo = printInfo
//        printController.printingItem = image
//
//        // 弹出系统打印机界面
//        printController.present(animated: true, completionHandler: nil)
    }
}
