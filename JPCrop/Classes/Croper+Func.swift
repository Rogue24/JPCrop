//
//  API.swift
//  JPCrop
//
//  Created by Rogue24 on 2022/3/5.
//

import UIKit

extension Croper {
    var isLandscapeImage: Bool {
        imageWHRatio > 1
    }
    
    func scaleValue(_ t: CGAffineTransform) -> CGFloat {
        sqrt(t.a * t.a + t.c * t.c)
    }
    
    func rotate(_ angle: CGFloat, isAutoZoom: Bool, animated: Bool) {
        guard animated else {
            rotate(angle, isAutoZoom: isAutoZoom)
            return
        }
        
        UIView.animate(withDuration: Self.animDuration, delay: 0, options: .curveEaseOut) {
            self.rotate(angle, isAutoZoom: isAutoZoom)
        }
    }
    
    func rotate(_ angle: CGFloat, isAutoZoom: Bool) {
        self.angle = angle
        let factor = fitFactor()
        
        var zoomScale = scrollView.zoomScale
        
        if !isAutoZoom {
            let oldScale = scaleValue(scrollView.transform)
            let newScale = factor.scale
            // scrollView 变大/变小多少，zoomScale 则变小/变大多少（反向缩放）
            // 否则在旋转过程中，裁剪区域在图片上即便有足够空间进行旋转（不超出图片区域），也会跟随 scrollView 变大变小
            zoomScale *= oldScale / newScale
        }
        
        let minZoomScale = scrollView.minimumZoomScale
        if zoomScale <= minZoomScale {
            zoomScale = minZoomScale
        }
        
        scrollView.transform = factor.transform
        scrollView.contentInset = factor.contentInset
        scrollView.zoomScale = zoomScale
    }
    
    func updateGrid(_ idleGridAlpha: Float, _ rotateGridAlpha: Float, animated: Bool = false) {
        
        if animated {
            buildAnimation(addTo: idleGridLayer, "opacity", idleGridAlpha, 0.12, timingFunctionName: .easeIn)
            buildAnimation(addTo: rotateGridLayer, "opacity", rotateGridAlpha, 0.12, timingFunctionName: .easeIn)
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        idleGridLayer.opacity = idleGridAlpha
        rotateGridLayer.opacity = rotateGridAlpha
        CATransaction.commit()
    }
}

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
        
        return .init(factor: factor,
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
    
    /// 刷新UI，适配当前窗口
    func updateUI(withRotateFactor factor: RotateFactor,
                  contentScalePoint: CGPoint,
                  zoomScale: CGFloat,
                  idleGridCount: GridCount?,
                  rotateGridCount: GridCount?,
                  animated: Bool) {
        let updateScrollView = {
            if zoomScale < 1 {
                self.scrollView.minimumZoomScale = 1
                self.scrollView.zoomScale = 1
            }
            self.scrollView.contentInset = factor.contentInset
            self.scrollView.contentOffset = self.fitOffset(contentScalePoint, contentInset: factor.contentInset)
        }
        
        // 边框路径
        let borderPath = UIBezierPath(rect: cropFrame)
        // 阴影路径
        let shadePath = UIBezierPath(rect: bounds)
        shadePath.append(borderPath)
        // 闲置网格路径
        if let obIdleGridCount = idleGridCount { self.idleGridCount = obIdleGridCount }
        let idleGridPath = buildGridPath(self.idleGridCount)
        // 旋转网格路径
        if let obRotateGridCount = rotateGridCount { self.rotateGridCount = obRotateGridCount }
        let rotateGridPath = buildGridPath(self.rotateGridCount)
        
        if animated {
            UIView.animate(withDuration: Self.animDuration, delay: 0, options: .curveEaseOut, animations: updateScrollView, completion: nil)
            buildAnimation(addTo: borderLayer, "path", borderPath.cgPath, Self.animDuration)
            buildAnimation(addTo: shadeLayer, "path", shadePath.cgPath, Self.animDuration)
            buildAnimation(addTo: idleGridLayer, "path", idleGridPath.cgPath, Self.animDuration)
            buildAnimation(addTo: rotateGridLayer, "path", rotateGridPath.cgPath, Self.animDuration)
        } else {
            updateScrollView()
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        borderLayer.path = borderPath.cgPath
        shadeLayer.path = shadePath.cgPath
        idleGridLayer.path = idleGridPath.cgPath
        rotateGridLayer.path = rotateGridPath.cgPath
        CATransaction.commit()
    }
}
