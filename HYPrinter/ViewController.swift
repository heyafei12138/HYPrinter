//
//  ViewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let view = UIView(frame: CGRect(x: 100, y: 100, width: 100, height: 100))
        view.backgroundColor = kmainColor
        self.view.addSubview(view)
        
        let view1 = UIView(frame: CGRect(x: 100, y: 200, width: 100, height: 100))
        view1.backgroundColor = kSubColor
        self.view.addSubview(view1)
        
    }


}

