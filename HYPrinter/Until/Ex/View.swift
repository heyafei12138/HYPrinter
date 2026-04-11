//
//  View.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import Foundation
import UIKit

final class DiagonalGradientView: UIView {
    
    private static let defaultStartColor = kmainColor ?? .systemBlue
    private static let defaultEndColor = kSubColor ?? .systemTeal
    
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }
    
    var startColor: UIColor = DiagonalGradientView.defaultStartColor {
        didSet { updateGradient() }
    }
    
    var endColor: UIColor = DiagonalGradientView.defaultEndColor {
        didSet { updateGradient() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        updateGradient()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.locations = [0, 1]
    }
}
