//
//  MainTabbarVC.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import Foundation
import UIKit
import VisionKit

protocol DocumentScanResultReceiving: AnyObject {
    func didReceiveScannedImages(_ images: [UIImage])
}


final class MainTabbarVC: UITabBarController {
    
    // MARK: - Public Property

    
    /// 扫描完成后的图片数组回调
    var onScannedImages: (([UIImage]) -> Void)?
    
    // MARK: - Private View
    
    /// 中间凸起容器
    private let centerActionContainer = UIView()
    
    /// 中间主按钮
    private let centerActionButton = UIButton(type: .custom)
    
    /// 中间标题
    private let centerActionTitleLabel = UILabel()
    
    /// 记录是否完成一次性布局
    private var hasConfiguredCenterActionLayout = false
    
    private weak var homeVC: HomeVC?
    private weak var printersVC: PrintersVC?
    private weak var historyVC: HistoryVC?
    private weak var mineVC: MineVC?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        buildChildControllers()
        applyTabBarStyle()
        buildCenterRaisedItem()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshTabBarFrameIfNeeded()
        layoutCenterRaisedItemIfNeeded()
    }
}

// MARK: - Build Controllers
extension MainTabbarVC {
    
    private func buildChildControllers() {
        let homeVC = HomeVC()
        
        homeVC.onBannerTap = { [weak self] in
            self?.switchToTab(index: 1)
        }
        homeVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(named: "tab1")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab1_select")?.withRenderingMode(.alwaysOriginal)
        )
        self.homeVC = homeVC
        
        let importVC = PrintersVC()
        
        importVC.tabBarItem = UITabBarItem(
            title: "Printers",
            image: UIImage(named: "tab2")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab2_select")?.withRenderingMode(.alwaysOriginal)
        )
        self.printersVC = importVC
        
        /// 中间占位控制器
        let centerPlaceholderVC = UIViewController()
        centerPlaceholderVC.tabBarItem = UITabBarItem(
            title: nil,
            image: nil,
            tag: 2
        )
        
        let historyVC = HistoryVC()
        
        historyVC.tabBarItem = UITabBarItem(
            title: "History",
            image: UIImage(named: "tab3")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab3_select")?.withRenderingMode(.alwaysOriginal)
        )
        self.historyVC = historyVC
        
        let profileVC = MineVC()
        
        profileVC.tabBarItem = UITabBarItem(
            title: "Mine",
            image: UIImage(named: "tab4")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab4_select")?.withRenderingMode(.alwaysOriginal)
        )
        self.mineVC = profileVC
        
        viewControllers = [
            wrapInNavigation(homeVC),
            wrapInNavigation(importVC),
            centerPlaceholderVC,
            wrapInNavigation(historyVC),
            wrapInNavigation(profileVC)
        ]
    }
    
    private func wrapInNavigation(_ rootVC: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: rootVC)
        nav.navigationBar.isHidden = true
        return nav
    }
    
   
    func switchToTab(index: Int) {
        guard let controllers = viewControllers,
              controllers.indices.contains(index),
              index != 2 else { return }
        selectedIndex = index
    }
}
// MARK: - TabBar Style
extension MainTabbarVC {
    
    private func applyTabBarStyle() {
        let normalColor = UIColor(hexString: "#707070")
        let activeColor = kmainColor
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)
        appearance.shadowImage = nil
        
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: normalColor,
            .font: kmiddleFont(fontSize: 11)
        ]
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: activeColor,
            .font: kmiddleFont(fontSize: 11)
        ]
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        /// 隐藏中间占位 item 的标题和图片偏移
        let stacked = appearance.stackedLayoutAppearance
        stacked.normal.iconColor = nil
        stacked.selected.iconColor = nil
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.tintColor = activeColor
        tabBar.unselectedItemTintColor = normalColor
    }
    
    private func refreshTabBarFrameIfNeeded() {
        var frame = tabBar.frame
        frame.size.height = 84
        frame.origin.y = view.bounds.height - 84
        tabBar.frame = frame
    }
}
// MARK: - Center Raised Item
extension MainTabbarVC {
    
    private func buildCenterRaisedItem() {
        /// 背景容器
        centerActionContainer.backgroundColor = kmainColor
        centerActionContainer.layer.cornerRadius = 30
        centerActionContainer.layer.masksToBounds = false
        centerActionContainer.layer.shadowColor = UIColor.black.cgColor
        centerActionContainer.layer.shadowOpacity = 0.12
        centerActionContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        centerActionContainer.layer.shadowRadius = 14
        
        /// 主按钮
        centerActionButton.adjustsImageWhenHighlighted = false
        centerActionButton.setImage(UIImage(named: "tab_middle"), for: .normal)
        centerActionButton.addTarget(self, action: #selector(handleCenterActionTap), for: .touchUpInside)
        
        /// 标题
        centerActionTitleLabel.text = "Scan"
        centerActionTitleLabel.textAlignment = .center
        centerActionTitleLabel.font = kmiddleFont(fontSize: 11)
        centerActionTitleLabel.textColor = kmainColor
        
        tabBar.addSubview(centerActionContainer)
        centerActionContainer.addSubview(centerActionButton)
//        centerActionContainer.addSubview(centerActionTitleLabel)
    }
    
    private func layoutCenterRaisedItemIfNeeded() {
        guard hasConfiguredCenterActionLayout == false else {
            updateCenterRaisedItemFrame()
            return
        }
        
        hasConfiguredCenterActionLayout = true
        updateCenterRaisedItemFrame()
    }
    
    private func updateCenterRaisedItemFrame() {
        let tabBarWidth = tabBar.bounds.width
        let containerWidth: CGFloat = 60
        let containerHeight: CGFloat = 60
        
        let containerX = (tabBarWidth - containerWidth) / 2.0
        let containerY: CGFloat = -8
        
        centerActionContainer.frame = CGRect(
            x: containerX,
            y: containerY,
            width: containerWidth,
            height: containerHeight
        )
        
        centerActionButton.frame = CGRect(
            x: 15,
            y: 15,
            width: 30,
            height: 30
        )
        
        centerActionTitleLabel.frame = CGRect(
            x: 4,
            y: 48,
            width: containerWidth - 8,
            height: 12
        )
    }
}
// MARK: - UITabBarControllerDelegate
extension MainTabbarVC: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        guard let index = viewControllers?.firstIndex(of: viewController) else {
            return true
        }
        
        /// 第 3 项是占位，不允许系统默认选中
        if index == 2 {
            handleCenterActionTap()
            return false
        }
        return true
    }
}
// MARK: - Center Action
extension MainTabbarVC: VNDocumentCameraViewControllerDelegate {
    
    @objc private func handleCenterActionTap() {
        guard VNDocumentCameraViewController.isSupported else {
            let alert = UIAlertController(
                title: "Not Supported",
                message: "This device does not support document scanning.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        present(scanner, animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                      didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true) {
            // 处理扫描结果
            var scannedImages: [UIImage] = []

            for i in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: i)
                scannedImages.append(image)
            }
            

            let vc = PhotoPreviewController(images: scannedImages)
            kWindow?.rootViewController?.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                      didFailWithError error: Error) {
        controller.dismiss(animated: true)
    }
    
    private func currentTopNavigationController() -> UINavigationController? {
        if let selectedNav = selectedViewController as? UINavigationController {
            return selectedNav
        }
        if let nav = selectedViewController?.navigationController {
            return nav
        }
        return viewControllers?
            .compactMap { $0 as? UINavigationController }
            .first
    }
}
