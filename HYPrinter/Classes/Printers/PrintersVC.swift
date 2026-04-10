//
//  PrintersVC.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import UIKit

class PrintersVC: BaseViewController {
    
    var pageHeaderTitle: String = "掌上打印" {
        didSet {
            titleLabel.text = pageHeaderTitle
        }
    }
    
    override var shouldHideNavigationBar: Bool {
        get { true }
        set { }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 30)
        label.textColor = .black
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func buildSubviews() {
        super.buildSubviews()
        
        titleLabel.text = pageHeaderTitle
        view.addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().inset(20)
        }
    }
    

}

