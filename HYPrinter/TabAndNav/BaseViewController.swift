//
//  BaseViewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//


import UIKit
import SafariServices

open class BaseViewController: UIViewController {
    
    // MARK: - Navigation Display
    
    /// 是否关闭自定义导航栏
    open var shouldHideNavigationBar: Bool {
        get { hiddenCustomNavigation }
        set { hiddenCustomNavigation = newValue }
    }
    
    /// 内部缓存字段
    private var hiddenCustomNavigation: Bool = false
    
    open override var title: String? {
        didSet {
            guard !shouldHideNavigationBar else { return }
            topBar.barTitle = title
        }
    }
    
    // MARK: - Status Bar
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }
    
    // MARK: - Gesture
    
    /// 是否允许侧滑返回
    public var allowsInteractivePop: Bool = false
    
    // MARK: - UI
    
    open lazy var topBar: KKNavigationView = {
        let bar = KKNavigationView()
        return bar
    }()
    
    // MARK: - Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        initializeAppearance()
        configureNavigationBar()
        buildSubviews()
        attachData()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if navigationController?.interactivePopGestureRecognizer?.isEnabled != allowsInteractivePop {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = allowsInteractivePop
        }
        
        // 处理某些系统场景导致的导航控制器高度异常问题
        let currentNavHeight = self.navigationController?.view.jk.height ?? kScreenHeight
        if currentNavHeight - kScreenHeight == kStatusBarHeight {
            navigationController?.viewControllers.forEach { $0.view.frame.size.height = kScreenHeight }
            navigationController?.view.frame.size.height = kScreenHeight
            
            let rootNav = UIApplication.jk.keyWindow?.rootViewController as? UINavigationController
            let rootTab = rootNav?.viewControllers.first as? UITabBarController
            rootTab?.view.frame.size.height = kScreenHeight
        }
    }
    
    deinit {
        
    }
}

// MARK: - Setup
extension BaseViewController {
    
    private func initializeAppearance() {
        view.backgroundColor = kBgColor
    }
    
    /// 预留给子类扩展 UI
    @objc open func buildSubviews() { }
    
    /// 预留给子类绑定数据
    @objc open func attachData() { }
    
    open func configureNavigationBar() {
        guard shouldHideNavigationBar == false else { return }
        
        view.addSubview(topBar)
        topBar.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(kNavHeight)
        }
        
        topBar.onTapLeft = { [weak self] in
            self?.handleBackEvent()
        }
        
        if navigationController?.viewControllers.count ?? 1 > 1 {
            topBar.updateLeftButton(image: UIImage(named: "back_black") ?? UIImage())
        }
    }
    
    open func refreshLeftNavigationItemIfNeeded() {
        guard topBar.leftButton.isHidden,
              navigationController?.viewControllers.count ?? 1 > 1 else { return }
        
        topBar.updateLeftButton(image: UIImage(named: "back_black") ?? UIImage())
    }
}

// MARK: - Action
extension BaseViewController {
    
    open func handleBackEvent() {
        popCurrentController()
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func showLoginIfNeeded() { }
    
    /// 内置浏览器打开网页
    func presentSafariPage(with url: URL) {
        let browser = SFSafariViewController(url: url)
        present(browser, animated: true)
    }
}

import UIKit

fileprivate let navTitleFontSize: CGFloat = 18
fileprivate let navTitleDefaultColor: UIColor = .black
fileprivate let navDefaultBgColor: UIColor = .clear

public let kIsPad = UIDevice.current.userInterfaceIdiom == .pad

open class KKNavigationView: UIView {
    
    // MARK: - Callback
    
    public var onTapLeft: (() -> Void)?
    public var onTapRight: (() -> Void)?
    
    // MARK: - Public Property
    
    public var barTitle: String? {
        willSet {
            centerTitleLabel.isHidden = false
            centerTitleLabel.text = newValue
        }
    }
    
    public var attributedBarTitle: NSAttributedString? {
        willSet {
            centerTitleLabel.isHidden = false
            centerTitleLabel.attributedText = newValue
        }
    }
    
    public var titleColor: UIColor? {
        willSet {
            centerTitleLabel.textColor = newValue
        }
    }
    
    public var titleFont: UIFont? {
        willSet {
            centerTitleLabel.font = newValue
        }
    }
    
    public var barBackgroundColor: UIColor? {
        willSet {
            bgImageView.isHidden = true
            bgPlainView.isHidden = false
            bgPlainView.backgroundColor = newValue
        }
    }
    
    public var barBackgroundImage: UIImage? {
        willSet {
            bgPlainView.isHidden = true
            bgImageView.isHidden = false
            bgImageView.image = newValue
        }
    }
    
    // MARK: - View
    
    open lazy var centerTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = navTitleDefaultColor
        label.font = .boldSystemFont(ofSize: navTitleFontSize)
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()
    
    open lazy var leftButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.isHidden = true
        btn.imageView?.contentMode = .center
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(handleLeftTap), for: .touchUpInside)
        return btn
    }()
    
    open lazy var rightButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.isHidden = true
        btn.imageView?.contentMode = .center
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(handleRightTap), for: .touchUpInside)
        return btn
    }()
    
    private lazy var bottomLineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor(hexString: "#DDDDDD")
        line.isHidden = false
        return line
    }()
    
    private lazy var bgPlainView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var bgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        return imageView
    }()
    
    private static var hasNotchScreen: Bool {
        kNotchScreen && !kIsPad
    }
    
    fileprivate static var totalBarHeight: Int {
        hasNotchScreen ? 88 : 64
    }
    
    // MARK: - Init
    
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: CGFloat(kNavHeight)))
        commonInit()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}
// MARK: - Build UI
extension KKNavigationView {
    
    private func commonInit() {
        addSubview(bgPlainView)
        addSubview(bgImageView)
        addSubview(centerTitleLabel)
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(bottomLineView)
        
        setupFramesAndConstraints()
        backgroundColor = .clear
        bgPlainView.backgroundColor = navDefaultBgColor
    }
    
    private func setupFramesAndConstraints() {
        let topInset = kStatusBarHeight
        let itemH: CGFloat = 44
        let itemW: CGFloat = 40
        let titleH: CGFloat = 44
        let titleW: CGFloat = kScreenWidth - 130 - 48
        
        bgPlainView.frame = bounds
        bgImageView.frame = bounds
        leftButton.frame = CGRect(x: 16, y: topInset, width: itemW, height: itemH)
        rightButton.frame = CGRect(x: kScreenWidth - itemW - 16, y: topInset, width: itemW, height: itemH)
        centerTitleLabel.frame = CGRect(x: 42, y: topInset, width: titleW, height: titleH)
        bottomLineView.frame = CGRect(x: 0, y: CGFloat(kNavHeight) - 0.5, width: kScreenWidth, height: 0.5)
        
        leftButton.contentHorizontalAlignment = .left
        leftButton.titleEdgeInsets = .zero
        leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        
        rightButton.contentHorizontalAlignment = .right
        rightButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        rightButton.titleLabel?.minimumScaleFactor = 0.5
        rightButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        bgPlainView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        centerTitleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(titleH)
            make.width.lessThanOrEqualTo(titleW)
            make.centerX.equalToSuperview()
        }
        
        leftButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalTo(centerTitleLabel)
            make.height.equalTo(itemH)
        }
        
        rightButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.size.bottom.equalTo(leftButton)
        }
    }
}
// MARK: - Public API
extension KKNavigationView {
    
    /// 控制底部分割线显示
    public func updateBottomLine(hidden: Bool) {
        bottomLineView.isHidden = hidden
    }
    
    /// 设置整体透明度
    public func updateBackgroundAlpha(_ alpha: CGFloat) {
        bgPlainView.alpha = alpha
        bgImageView.alpha = alpha
        bottomLineView.alpha = alpha
    }
    
    /// 设置统一着色
    public func updateTintColor(_ color: UIColor) {
        leftButton.setTitleColor(color, for: .normal)
        rightButton.setTitleColor(color, for: .normal)
        centerTitleLabel.textColor = color
    }
    
    /// 更新左侧按钮图片
    public func updateLeftButton(image: UIImage, highlighted: UIImage? = nil) {
        configureLeftButton(
            image: image,
            highlighted: highlighted ?? image,
            title: nil,
            titleColor: nil
        )
    }
    
    /// 更新右侧按钮图片
    public func updateRightButton(image: UIImage, highlighted: UIImage) {
        configureRightButton(
            image: image,
            highlighted: highlighted,
            title: nil,
            titleColor: nil
        )
    }
    
    /// 更新左侧按钮文字
    public func updateLeftButton(title: String, color: UIColor) {
        configureLeftButton(
            image: nil,
            highlighted: nil,
            title: title,
            titleColor: color
        )
    }
    
    /// 更新右侧按钮文字
    public func updateRightButton(title: String, color: UIColor) {
        configureRightButton(
            image: nil,
            highlighted: nil,
            title: title,
            titleColor: color
        )
    }
    
    private func configureLeftButton(image: UIImage?, highlighted: UIImage?, title: String?, titleColor: UIColor?) {
        leftButton.isHidden = false
        leftButton.setImage(image, for: .normal)
        leftButton.setImage(highlighted, for: .highlighted)
        leftButton.setTitle(title, for: .normal)
        leftButton.setTitleColor(titleColor, for: .normal)
    }
    
    private func configureRightButton(image: UIImage?, highlighted: UIImage?, title: String?, titleColor: UIColor?) {
        rightButton.isHidden = false
        rightButton.setImage(image, for: .normal)
        rightButton.setImage(highlighted, for: .highlighted)
        rightButton.setTitle(title, for: .normal)
        rightButton.setTitleColor(titleColor, for: .normal)
    }
}
// MARK: - Event
extension KKNavigationView {
    
    @objc private func handleLeftTap() {
        if let block = onTapLeft {
            block()
        } else {
            guard let currentVC = UIViewController.jk.topViewController() else { return }
            currentVC.popCurrentController()
        }
    }
    
    @objc private func handleRightTap() {
        onTapRight?()
    }
}
