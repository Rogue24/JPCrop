//
//  Croper+Func.swift
//  JPCrop
//
//  Created by Rogue24 on 2022/3/5.
//

import UIKit

extension Croper {
    /// 更新裁剪宽高比，并获取改变前后的差值
    func resetCropWHRatio(_ whRatio: CGFloat) -> DiffFactor {
        cropWHRatio = fitCropWHRatio(whRatio, isCallBack: true)
        
        // 更新可裁剪区域
        let oldCropFrame = cropFrame
        cropFrame = fitCropFrame()
        
        // 更新 imageView 基于并适配 cropFrame 后的原始 Size
        imageBoundsSize = fitImageSize()
        
        // 更新基于并适配 cropFrame 后的最小边距
        minMargin = UIEdgeInsets(top: cropFrame.origin.y,
                                 left: cropFrame.origin.x,
                                 bottom: bounds.height - cropFrame.maxY,
                                 right: bounds.width - cropFrame.maxX)
        
        // 获取 scrollView 最合适（不会超出）cropFrame 和 radian 的 transform 和 contentInset
        let factor = fitFactor()
        
        // 当前裁剪框中心点相对于当前内容图片的百分比位置
        var contentScalePoint = CGPoint(x: 0.5, y: 0.5)
        var zoomScale: CGFloat = 1
        if imageView.bounds.width > 0 {
            let fromPoint = CGPoint(x: oldCropFrame.midX, y: oldCropFrame.midY)
            let convertOffset = borderLayer.convert(fromPoint, to: imageView.layer)
            contentScalePoint.x = convertOffset.x / imageView.bounds.width
            contentScalePoint.y = convertOffset.y / imageView.bounds.height
            
            let diffScale = scaleValue(scrollView.transform) / scaleValue(factor.transform)
            zoomScale = imageView.frame.width / imageBoundsSize.width * diffScale
        }
        
        let imageFrameSize = CGSize(width: imageBoundsSize.width * zoomScale,
                                    height: imageBoundsSize.height * zoomScale)
        
        return DiffFactor(factor: factor,
                          contentScalePoint: contentScalePoint,
                          zoomScale: zoomScale,
                          imageFrameSize: imageFrameSize)
    }
    
    /// 无痕刷新 scrollView 改变后的 transform 和其他差值（让 scrollView 形变后相对于之前的 UI 状态“看上去”没有变化一样）
    func tracelessUpdateTransform(_ transform: CGAffineTransform,
                                  contentScalePoint: CGPoint,
                                  zoomScale: CGFloat,
                                  imageFrameSize: CGSize) {
        let ax = cropFrame.midX / bounds.width
        let ay = cropFrame.midY / bounds.height
        scrollView.layer.anchorPoint = CGPoint(x: ax, y: ay)
        scrollView.layer.position = CGPoint(x: ax * bounds.width, y: ay * bounds.height)
        
        imageView.bounds = CGRect(origin: .zero, size: imageBoundsSize)
        
        scrollView.transform = transform
        if zoomScale < 1 { scrollView.minimumZoomScale = zoomScale }
        scrollView.zoomScale = zoomScale
        scrollView.contentSize = imageFrameSize
        
        imageView.frame = CGRect(origin: .zero, size: imageFrameSize)
        
        scrollView.contentOffset = fitOffset(contentScalePoint, contentSize: imageFrameSize)
    }
}

extension Croper {
    static func addAnimation<T>(to layer: CALayer, 
                                _ keyPath: String, _ toValue: T,
                                duration: TimeInterval? = nil,
                                curve: CAMediaTimingFunctionName? = nil) {
        let anim = CABasicAnimation(keyPath: keyPath)
        anim.fromValue = layer.value(forKeyPath: keyPath)
        anim.toValue = toValue
        anim.fillMode = .backwards
        anim.duration = duration ?? animDuration
        anim.timingFunction = CAMediaTimingFunction(name: curve ?? .easeOut)
        layer.add(anim, forKey: keyPath)
    }
    
    static func executeInMainQueue(isAsync: Bool = false, block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
            return
        }
        
        if isAsync {
            DispatchQueue.main.async(execute: block)
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }
}
