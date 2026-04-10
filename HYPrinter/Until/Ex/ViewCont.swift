//
//  ViewController.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

import Foundation
import UIKit

extension UIViewController {
    
    // MARK: - Present
    
    /// 从 storyboard 拉起初始控制器
    func presentController(fromStoryboard storyboardName: String) {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        guard let target = storyboard.instantiateInitialViewController() else { return }
        presentController(target)
    }
    
    /// 直接弹出控制器
    func presentController(_ target: UIViewController) {
        if #available(iOS 13.0, *) {
            target.modalPresentationStyle = .fullScreen
        }
        present(target, animated: true)
    }
    
    // MARK: - Push
    
    /// 从 storyboard push 初始控制器
    func pushController(fromStoryboard storyboardName: String) {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        guard let target = storyboard.instantiateInitialViewController() else { return }
        pushController(target)
    }
    
    /// push 指定控制器
    func pushController(_ target: UIViewController) {
        if let nav = self as? UINavigationController {
            nav.pushViewController(target, animated: true)
            return
        }
        
        target.hidesBottomBarWhenPushed = true
        navigationController?.pushSafely(target, animated: true)
    }
    
    /// 可控制动画开关的 push
    func pushController(_ target: UIViewController, animated: Bool = true) {
        if let nav = self as? UINavigationController {
            nav.pushViewController(target, animated: animated)
            return
        }
        
        target.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(target, animated: animated)
    }
    
    // MARK: - Pop
    
    /// 返回上一级
    func popCurrentController(_ animated: Bool = true) {
        if let nav = self as? UINavigationController {
            nav.popViewController(animated: animated)
        } else {
            navigationController?.popViewController(animated: animated)
        }
    }
    
    /// 返回根控制器
    func popToRootController() {
        if let nav = self as? UINavigationController {
            nav.popToRootViewController(animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    /// 返回到指定控制器
    func popBack(to controller: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if let nav = self as? UINavigationController {
                nav.popToViewController(controller, animated: true)
            } else {
                self.navigationController?.popToViewController(controller, animated: true)
            }
        }
    }
    
    // MARK: - Responder
    
    /// 递归查找第一响应者
    func searchFirstResponder(in containerView: UIView) -> UIView? {
        if containerView.isFirstResponder {
            return containerView
        }
        
        for child in containerView.subviews {
            if let responder = searchFirstResponder(in: child) {
                return responder
            }
        }
        return nil
    }
}

extension UINavigationController {
    
    /// 安全 push，避免重复压栈
    func pushSafely(_ controller: UIViewController, animated: Bool) {
        if let currentTop = topViewController, currentTop == controller {
            return
        }
        pushViewController(controller, animated: animated)
    }
}
