//
//  ViewUtiles.swift
//  HYPrinter
//
//  Created by hebert on 2026/4/10.
//

@_exported import JKSwiftExtension
@_exported import SnapKit

import Foundation

let kWindow = UIApplication.jk.keyWindow
let kScreenWidth = UIScreen.main.bounds.width
let kScreenHeight = UIScreen.main.bounds.height
// MARK: - 状态栏高度和导航条高度
let kStatusBarHeight = jk_kStatusBarFrameH
let kNavHeight = 44 + kStatusBarHeight
// MARK: - 底部安全区域高度和tabbar的高度
public var kBottomSafeHeight = jk_kSafeDistanceBottom
let kTabbarHeight = jk_kTabbarFrameH
// 判断是否是刘海屏
var kNotchScreen: Bool {
    return kStatusBarHeight > 20 && kBottomSafeHeight > 0
}
let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    ?? ""
let kmainColor = UIColor(hexString: "#2F80ED")!
let kSubColor = UIColor(hexString: "#5BC0BE")!
let kBgColor = UIColor(hexString: "#F6F8FC")!




@inline(__always)
func kmiddleFont(fontSize: CGFloat) -> UIFont {
    UIFont.systemFont(ofSize: fontSize, weight: .medium)
}
func kboldFont(fontSize: CGFloat) -> UIFont {
    UIFont.systemFont(ofSize: fontSize, weight: .bold)
}
