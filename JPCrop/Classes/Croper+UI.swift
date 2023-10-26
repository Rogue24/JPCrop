//
//  Croper+UI.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/23.
//

import UIKit

extension Croper {
    /// 初始化UI
    func setupUI() {
        clipsToBounds = true
        backgroundColor = .black
        
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 10
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.frame = bounds
        addSubview(scrollView)
        
        imageView.image = image
        scrollView.addSubview(imageView)
        
        shadeLayer.frame = bounds
        shadeLayer.fillColor = UIColor(white: 0, alpha: 0.5).cgColor
        shadeLayer.fillRule = .evenOdd
        shadeLayer.strokeColor = UIColor.clear.cgColor
        shadeLayer.lineWidth = 0
        layer.addSublayer(shadeLayer)
        
        idleGridLayer.frame = bounds
        idleGridLayer.fillColor = UIColor.clear.cgColor
        idleGridLayer.strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
        idleGridLayer.lineWidth = 0.35
        layer.addSublayer(idleGridLayer)
        
        rotateGridLayer.frame = bounds
        rotateGridLayer.fillColor = UIColor.clear.cgColor
        rotateGridLayer.strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
        rotateGridLayer.lineWidth = 0.35
        rotateGridLayer.opacity = 0
        layer.addSublayer(rotateGridLayer)
        
        borderLayer.frame = bounds
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)
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
        let idleGridPath = buildGridPath(with: self.idleGridCount)
        // 旋转网格路径
        if let obRotateGridCount = rotateGridCount { self.rotateGridCount = obRotateGridCount }
        let rotateGridPath = buildGridPath(with: self.rotateGridCount)
        
        if animated {
            UIView.animate(withDuration: Self.animDuration, delay: 0, options: .curveEaseOut, animations: updateScrollView, completion: nil)
            Self.addAnimation(to: borderLayer, "path", borderPath.cgPath)
            Self.addAnimation(to: shadeLayer, "path", shadePath.cgPath)
            Self.addAnimation(to: idleGridLayer, "path", idleGridPath.cgPath)
            Self.addAnimation(to: rotateGridLayer, "path", rotateGridPath.cgPath)
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

extension Croper {
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
}

extension Croper {
    func buildGridPath(with gridCount: (verCount: Int, horCount: Int)) -> UIBezierPath {
        let gridPath = UIBezierPath()
        guard gridCount.verCount > 1, gridCount.horCount > 1 else { return gridPath }
        
        let verSpace = cropFrame.height / CGFloat(gridCount.verCount)
        let horSpace = cropFrame.width / CGFloat(gridCount.horCount)
        
        for i in 1 ..< gridCount.verCount {
            let px = cropFrame.origin.x
            let py = cropFrame.origin.y + verSpace * CGFloat(i)
            gridPath.move(to: CGPoint(x: px, y: py))
            gridPath.addLine(to: CGPoint(x: px + cropFrame.width, y: py))
        }
        
        for i in 1 ..< gridCount.horCount {
            let px = cropFrame.origin.x + horSpace * CGFloat(i)
            let py = cropFrame.origin.y
            gridPath.move(to: CGPoint(x: px, y: py))
            gridPath.addLine(to: CGPoint(x: px, y: py + cropFrame.height))
        }
        
        return gridPath
    }
    
    func updateGridAlpha(_ idleGridAlpha: Float,
                         _ rotateGridAlpha: Float,
                         animated: Bool = false) {
        if animated {
            Self.addAnimation(to: idleGridLayer, "opacity", idleGridAlpha, duration: 0.12, curve: .easeIn)
            Self.addAnimation(to: rotateGridLayer, "opacity", rotateGridAlpha, duration: 0.12, curve: .easeIn)
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        idleGridLayer.opacity = idleGridAlpha
        rotateGridLayer.opacity = rotateGridAlpha
        CATransaction.commit()
    }
}
