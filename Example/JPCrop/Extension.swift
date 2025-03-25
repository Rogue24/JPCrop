//
//  JP.Extension.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

private let JPrintQueue = DispatchQueue(label: "JPrintQueue")
/// 自定义日志
func JPrint(_ msg: Any..., file: NSString = #file, line: Int = #line, fn: String = #function) {
#if DEBUG
    guard msg.count != 0, let lastItem = msg.last else { return }
    
    // 时间+文件位置+行数
    let date = hhmmssSSFormatter.string(from: Date()).utf8
    let fileName = (file.lastPathComponent as NSString).deletingPathExtension
    let prefix = "[\(date)] [\(fileName) \(fn)] [第\(line)行]:"
    
    // 获取【除最后一个】的其他部分
    let items = msg.count > 1 ? msg[..<(msg.count - 1)] : []
    
    JPrintQueue.sync {
        print(prefix, terminator: " ")
        items.forEach { print($0, terminator: " ") }
        print(lastItem)
    }
#endif
}

#if DEBUG
let hhmmssSSFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm:ss:SS"
    return formatter
}()
#endif

extension UIScreen {
    static var mainScale: CGFloat { main.scale }
    static var mainBounds: CGRect { main.bounds }
    static var mainSize: CGSize { main.bounds.size }
    static var mainWidth: CGFloat { main.bounds.width }
    static var mainHeight: CGFloat { main.bounds.height }
}

let ScreenScale: CGFloat = UIScreen.mainScale

let PortraitScreenWidth: CGFloat = min(UIScreen.mainWidth, UIScreen.mainHeight)
let PortraitScreenHeight: CGFloat = max(UIScreen.mainWidth, UIScreen.mainHeight)
let PortraitScreenSize: CGSize = CGSize(width: PortraitScreenWidth, height: PortraitScreenHeight)
let PortraitScreenBounds: CGRect = CGRect(origin: .zero, size: PortraitScreenSize)

let LandscapeScreenWidth: CGFloat = PortraitScreenHeight
let LandscapeScreenHeight: CGFloat = PortraitScreenWidth
let LandscapeScreenSize: CGSize = CGSize(width: LandscapeScreenWidth, height: LandscapeScreenHeight)
let LandscapeScreenBounds: CGRect = CGRect(origin: .zero, size: LandscapeScreenSize)

let IsBangsScreen: Bool = PortraitScreenHeight > 736.0

private var _DiffTabBarH: CGFloat = 0
var DiffTabBarH: CGFloat {
    guard _DiffTabBarH == 0 else { return _DiffTabBarH }
    
    if #available(iOS 11.0, *),
       let window = UIApplication.shared.delegate?.window ?? UIApplication.shared.windows.first
    {
        _DiffTabBarH = window.safeAreaInsets.bottom
    }
    
    guard _DiffTabBarH == 0 else { return _DiffTabBarH }
    
    if IsBangsScreen {
        return 34.0
    } else {
        return 0
    }
}
let BaseTabBarH: CGFloat = 49.0
let TabBarH: CGFloat = BaseTabBarH + DiffTabBarH

private var _StatusBarH: CGFloat = 0
var StatusBarH: CGFloat {
    guard _StatusBarH == 0 else { return _StatusBarH }
    
    if #available(iOS 11.0, *) {
        if let window = UIApplication.shared.delegate?.window ?? UIApplication.shared.windows.first {
            if #available(iOS 13.0, *) {
                if let statusBarManager = window.windowScene?.statusBarManager {
                    _StatusBarH = statusBarManager.statusBarFrame.height
                } else {
                    _StatusBarH = window.safeAreaInsets.top
                }
            } else {
                _StatusBarH = window.safeAreaInsets.top
            }
        } else {
            if #available(iOS 13.0, *) {} else {
                _StatusBarH = UIApplication.shared.statusBarFrame.height
            }
        }
    } else {
        _StatusBarH = UIApplication.shared.statusBarFrame.height
    }
    
    guard _StatusBarH == 0 else { return _StatusBarH }
    
    if IsBangsScreen {
        if #available(iOS 13.0, *) {
            return 48.0
        } else {
            return 44.0
        }
    } else {
        return BaseStatusBarH
    }
}
let BaseStatusBarH: CGFloat = 20.0
let DiffStatusBarH: CGFloat = StatusBarH - BaseStatusBarH

let NavBarH: CGFloat = 44.0
let NavTopMargin: CGFloat = StatusBarH + NavBarH

let BasisWScale: CGFloat = PortraitScreenWidth / 375.0
let BasisHScale: CGFloat = (PortraitScreenHeight - DiffStatusBarH - DiffTabBarH) / 667.0

extension UIImage {
    func fixOrientation() -> UIImage {
        guard imageOrientation != .up, let imageRef = cgImage else { return self }
         
        var transform = CGAffineTransform.identity
         
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            
        default:
            break
        }
         
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
             
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
             
        default:
            break
        }
         
        guard let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: imageRef.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: imageRef.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: imageRef.bitmapInfo.rawValue) else {
            return self
        }
        
        let drawRect: CGRect
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            drawRect =  CGRect(x: 0, y: 0, width: size.height, height: size.width)
        default:
            drawRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
        
        context.concatenate(transform)
        context.draw(imageRef, in: drawRect)
        
        guard let newImageRef = context.makeImage() else { return self }
        return UIImage(cgImage: newImageRef)
    }
}

extension Int {
    var px: CGFloat { CGFloat(self) * BasisWScale }
}

extension Float {
    var px: CGFloat { CGFloat(self) * BasisWScale }
}

extension Double {
    var px: CGFloat { CGFloat(self) * BasisWScale }
}

extension CGFloat {
    var px: CGFloat { self * BasisWScale }
}

extension CGPoint {
    var px: CGPoint { .init(x: self.x * BasisWScale, y: self.y * BasisWScale) }
    
    static func px(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * BasisWScale, y: y * BasisWScale)
    }
}

extension CGSize {
    var px: CGSize { .init(width: self.width * BasisWScale, height: self.height * BasisWScale) }
    
    static func px(_ w: CGFloat, _ h: CGFloat) -> CGSize {
        CGSize(width: w * BasisWScale, height: h * BasisWScale)
    }
}

extension CGRect {
    var px: CGRect { .init(x: self.origin.x * BasisWScale,
                           y: self.origin.y * BasisWScale,
                           width: self.width * BasisWScale,
                           height: self.height * BasisWScale) }
    
    static func px(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * BasisWScale,
               y: y * BasisWScale,
               width: w * BasisWScale,
               height: h * BasisWScale)
    }
    
    static func px(_ origin: CGPoint, _ size: CGSize) -> CGRect {
        CGRect(origin: .init(x: origin.x * BasisWScale,
                             y: origin.y * BasisWScale),
               size: .init(width: size.width * BasisWScale,
                           height: size.height * BasisWScale))
    }
}

extension UIColor {
    class var randomColor: UIColor { randomColor() }
    class func randomColor(_ a: CGFloat = 1.0) -> UIColor {
        UIColor(red: CGFloat.random(in: 0...255) / 255.0,
                green: CGFloat.random(in: 0...255) / 255.0,
                blue: CGFloat.random(in: 0...255) / 255.0,
                alpha: a)
    }
}
