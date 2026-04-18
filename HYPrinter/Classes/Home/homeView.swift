//
//  homeView.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/13.
//

import Foundation

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
        label.text = "Quick Device Connect"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .white
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to see more"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.88)
        return label
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "home_arrow_icon"))
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

final class HomeFeatureGridView: UIView {
    private let leftCardView = HomeLargeFeatureCardView(
        imageName: "home_cat_icLeft",
        title: "Photo Print",
        subtitle: "Print from your photo album\nin one tap"
    )
    
    private let topRightCardView = HomeCompactFeatureCardView(
        imageName: "home_cat_ic",
        iconSystemName: "printer.fill",
        title: "Document Print"
    )
    
    private let bottomRightCardView = HomeCompactFeatureCardView(
        imageName: "home_cat_ic2",
        iconSystemName: "doc.text.viewfinder",
        title: "Template Print"
    )
    
    private let rightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    var onTap: ((Int) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        addSubview(leftCardView)
        addSubview(rightStackView)
        
        rightStackView.addArrangedSubview(topRightCardView)
        rightStackView.addArrangedSubview(bottomRightCardView)
        
        leftCardView.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.54)
        }
        
        rightStackView.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(leftCardView.snp.right).offset(12)
        }
        leftCardView.jk.addGestureTap { _ in
            self.onTap?(0)
        }
        topRightCardView.jk.addGestureTap { _ in
            self.onTap?(1)
        }
        bottomRightCardView.jk.addGestureTap { _ in
            self.onTap?(2)
        }
    }
}

final class HomeLargeFeatureCardView: UIView {
    private let backgroundImageView = UIImageView()
    private let gradientView = BannerGradientView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .white
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        label.numberOfLines = 0
        return label
    }()
    
    init(imageName: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        backgroundImageView.image = UIImage(named: imageName)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        
        addSubview(backgroundImageView)
        addSubview(gradientView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        gradientView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(90)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(subtitleLabel)
            make.top.equalToSuperview().inset(16)

        }
        subtitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.right.equalToSuperview().inset(76)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        
        
    }
}

final class HomeCompactFeatureCardView: UIView {
    private let backgroundImageView = UIImageView()
    
    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        return view
    }()
    
    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let iconImageView = UIImageView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    init(imageName: String, iconSystemName: String, title: String) {
        super.init(frame: .zero)
        backgroundImageView.image = UIImage(named: imageName)
        iconImageView.image = UIImage(systemName: iconSystemName)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        titleLabel.text = title
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        
        addSubview(backgroundImageView)
        addSubview(dimView)
        addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        addSubview(titleLabel)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconBackgroundView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconBackgroundView.snp.right).offset(10)
            make.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
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

enum HomeMoreModule: CaseIterable {
//    case email
    case label
    case text
    case web
    case iCloud
    case contact
    
    var iconName: String {
        switch self {
//        case .email:
//            return "email_home_icon"
        case .label:
            return "label_home_icon"
        case .text:
            return "text_home_icon"
        case .web:
            return "web_home_icon"
        case .iCloud:
            return "icloud_home_icon"
        case .contact:
            return "contact_home_icon"
        }
    }
    
    var title: String {
        switch self {
//        case .email:
//            return "Email"
        case .label:
            return "Stickers"
        case .text:
            return "Text"
        case .web:
            return "Web"
        case .iCloud:
            return "iCloud"
        case .contact:
            return "Contacts"
        }
    }
}

final class HomeMoreModulesSectionView: UIView {
    var onItemTap: ((HomeMoreModule) -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "✨ More Modules"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    private let gridContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        return view
    }()
    
    private let rowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private let moduleItems = HomeMoreModule.allCases
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        addSubview(titleLabel)
        addSubview(gridContainerView)
        gridContainerView.addSubview(rowsStackView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        
        gridContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
        
        rowsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14))
        }
        
        let chunks = stride(from: 0, to: moduleItems.count, by: 3).map {
            Array(moduleItems[$0..<min($0 + 3, moduleItems.count)])
        }
        
        for (rowIndex, rowItems) in chunks.enumerated() {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.spacing = 12
            rowStackView.distribution = .fillEqually
            
            for (columnIndex, item) in rowItems.enumerated() {
                let cardView = HomeModuleEntryView(iconName: item.iconName, title: item.title)
                cardView.tag = rowIndex * 3 + columnIndex
                cardView.addTarget(self, action: #selector(handleModuleTap(_:)), for: .touchUpInside)
                rowStackView.addArrangedSubview(cardView)
            }
            
            if rowItems.count < 3 {
                for _ in rowItems.count..<3 {
                    let placeholderView = UIView()
                    placeholderView.isHidden = true
                    rowStackView.addArrangedSubview(placeholderView)
                }
            }
            
            rowsStackView.addArrangedSubview(rowStackView)
        }
    }
    
    @objc private func handleModuleTap(_ sender: HomeModuleEntryView) {
        guard moduleItems.indices.contains(sender.tag) else { return }
        onItemTap?(moduleItems[sender.tag])
    }
}

final class HomeModuleEntryView: UIControl {
    private let iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = kSubColor.withAlphaComponent(0.1)
        view.layer.cornerRadius = 30
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = kmainColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(hexString: "#222222") ?? .black
        label.textAlignment = .center
        return label
    }()
    
    init(iconName: String, title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(hexString: "#F8FAFD") ?? .systemGray6
        layer.cornerRadius = 16
        iconImageView.image = UIImage(named: iconName)
        titleLabel.text = title
        buildSubviews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func buildSubviews() {
        addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        addSubview(titleLabel)
        
        iconBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(25)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(6)
        }
    }
}
