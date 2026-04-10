//
//  HomeVC.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import UIKit

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
    
    private let bannerView = HomeBannerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        titleLabel.text = pageHeaderTitle
        
        view.addSubview(titleLabel)
        view.addSubview(bannerView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(20)
        }
        
        bannerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(196)
        }
        
        bannerView.onTap = { [weak self] in
            self?.onBannerTap?()
        }
    }

}


final class HomeBannerView: UIControl {
    var onTap: (() -> Void)?
    
    private let artworkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "homebanner_ic"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let gradientView = BannerGradientView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "设备快连"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .white
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "点击查看更多"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.88)
        return label
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "arrow_right"))
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        layer.masksToBounds = true
        buildSubviews()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        addSubview(artworkImageView)
        addSubview(gradientView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(imageView)
        
        artworkImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        gradientView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(110)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.bottom.equalToSuperview().inset(18)
            make.right.equalToSuperview().inset(18)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(subtitleLabel)
            make.right.equalToSuperview().inset(18)
            make.bottom.equalTo(subtitleLabel.snp.top).offset(-4)
        }
        imageView.snp.makeConstraints { make in
            make.centerY.equalTo(subtitleLabel)
            make.right.equalToSuperview().inset(18)
            make.width.height.equalTo(20)
        }
    }
    
    @objc private func handleTap() {
        onTap?()
    }
}

final class BannerGradientView: UIView {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        if let gradientLayer = layer as? CAGradientLayer {
            gradientLayer.colors = [
                UIColor.black.withAlphaComponent(0).cgColor,
                UIColor.black.withAlphaComponent(0.82).cgColor
            ]
            gradientLayer.locations = [0, 1]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
