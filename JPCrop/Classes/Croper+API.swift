//
//  Croper+API.swift
//  JPCrop
//
//  Created by Rogue24 on 2022/3/5.
//

// MARK: - 公开API
import UIKit

public extension Croper {
    // MARK: 获取当前的Configure（当前的裁剪元素、状态）
    /// 获取当前的`Configure`，可用于保存当前的裁剪状态，下一次打开恢复状态
    func getCurrentConfigure() -> Configure {
        var configure = Configure(image,
                                  cropWHRatio: cropWHRatio,
                                  originAngle: originAngle,
                                  angle: angle)
        
        Self.executeInMainQueue {
            configure.zoomScale = self.scrollView.zoomScale
            configure.contentOffset = self.scrollView.contentOffset
        }
        
        return configure
    }
    
    // MARK: 旋转
    /// 旋转（单位：角度，基于`originAngle`，范围：`-45°` ~ `45°`）
    func rotate(_ angle: CGFloat) {
        rotate(angle, isAutoZoom: false)
    }
    
    // MARK: 向左旋转
    /// 向左旋转（`originAngle - 90°`）
    func rotateLeft(animated: Bool) {
        let angle = self.angle
        originAngle = originAngle.prev
        rotate(angle, isAutoZoom: true, animated: animated)
    }
    
    // MARK: 向右旋转
    /// 向右旋转（`originAngle + 90°`）
    func rotateRight(animated: Bool) {
        let angle = self.angle
        originAngle = originAngle.next
        rotate(angle, isAutoZoom: true, animated: animated)
    }
    
    // MARK: 切换裁剪框的宽高比
    /// 刷新裁剪比例
    /// - Parameters:
    ///   - idleGridCount: 闲置时的网格数
    ///   - rotateGridCount: 旋转时的网格数
    func updateCropWHRatio(_ cropWHRatio: CGFloat,
                           idleGridCount: GridCount? = nil,
                           rotateGridCount: GridCount? = nil,
                           animated: Bool = false) {
        // 1.算出改变后的UI数值，和改变前后的差值（获取 scrollView 最合适（不会超出）cropFrame 和 radian 的 transform 和 contentInset）
        let diff = resetCropWHRatio(cropWHRatio)
        
        // 2.立马设置 scrollView 改变后的 transform，和其他的一些差值，让 scrollView 形变后相对于之前的 UI 状态“看上去”没有变化一样
        tracelessUpdateTransform(diff.factor.transform,
                                 contentScalePoint: diff.contentScalePoint,
                                 zoomScale: diff.zoomScale,
                                 imageFrameSize: diff.imageFrameSize)
        
        // 3.再通过动画刷新UI，适配当前窗口，也就是把差值还原回去
        updateUI(withRotateFactor: diff.factor,
                 contentScalePoint: diff.contentScalePoint,
                 zoomScale: diff.zoomScale,
                 idleGridCount: idleGridCount,
                 rotateGridCount: rotateGridCount,
                 animated: animated)
    }
    
    // MARK: 显示旋转网格
    /// 显示旋转时的网格数
    func showRotateGrid(animated: Bool = false) {
        updateGridAlpha(0, 1, animated: animated)
    }
    
    // MARK: 隐藏旋转网格
    /// 隐藏旋转时的网格数
    func hideRotateGrid(animated: Bool = false) {
        updateGridAlpha(1, 0, animated: animated)
    }
    
    // MARK: 恢复
    /// 恢复：【调整角度 = 0】+【缩放比例 = 1】+【中心点】
    func recover(animated: Bool = false) {
        angle = 0
        
        let factor = fitFactor()
        let updateScrollView = {
            self.scrollView.zoomScale = 1
            self.scrollView.transform = factor.transform
            self.scrollView.contentInset = factor.contentInset
            self.scrollView.contentOffset = self.fitOffset(CGPoint(x: 0.5, y: 0.5), contentInset: factor.contentInset)
        }
        
        if animated {
            UIView.animate(withDuration: Self.animDuration, delay: 0, options: .curveEaseOut, animations: updateScrollView, completion: nil)
        } else {
            updateScrollView()
        }
    }
    
    // MARK: 裁剪·异步
    /// 异步裁剪
    /// - Parameters:
    ///   - compressScale: 压缩比例，默认为1，即原图尺寸
    func asyncCrop(_ compressScale: CGFloat = 1, _ cropDone: @escaping (_ result: UIImage?) -> ()) {
        DispatchQueue.global().async {
            let result = self.crop(compressScale)
            DispatchQueue.main.async {
                cropDone(result)
            }
        }
    }
    
    // MARK: 裁剪·同步
    /// 同步裁剪
    /// - Parameters:
    ///   - compressScale: 压缩比例，默认为1，即原图尺寸
    func crop(_ compressScale: CGFloat = 1) -> UIImage? {
        guard let imageRef = getFixedImageRef() else { return nil }
        let factor = getCropFactorSafely()
        
        let width = CGFloat(imageRef.width) * compressScale
        let height = CGFloat(imageRef.height) * compressScale
        
        // 获取裁剪尺寸和裁剪区域
        let cropWHRatio = factor.cropWHRatio
        var rendSize: CGSize
        if width > height {
            rendSize = CGSize(width: height * cropWHRatio, height: height)
            if rendSize.width > width {
                rendSize = CGSize(width: width, height: width / cropWHRatio)
            }
        } else {
            rendSize = CGSize(width: width, height: width / cropWHRatio)
            if rendSize.height > height {
                rendSize = CGSize(width: height * cropWHRatio, height: height)
            }
        }
        
        var bitmapRawValue = CGBitmapInfo.byteOrder32Little.rawValue
        let alphaInfo = imageRef.alphaInfo
        if alphaInfo == .premultipliedLast ||
            alphaInfo == .premultipliedFirst ||
            alphaInfo == .last ||
            alphaInfo == .first {
            bitmapRawValue += CGImageAlphaInfo.premultipliedFirst.rawValue
        } else {
            bitmapRawValue += CGImageAlphaInfo.noneSkipFirst.rawValue
        }
        
        guard let context = CGContext(data: nil,
                                      width: Int(rendSize.width),
                                      height: Int(rendSize.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: bitmapRawValue) else { return nil }
        
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        context.interpolationQuality = .high
        
        let scale = factor.scale
        let radian = factor.radian
        
        let ibHeight = factor.imageBoundsHeight
        let iScale = CGFloat(imageRef.height) / (ibHeight * scale)
        var translate = factor.convertTranslate
        translate.y = ibHeight - translate.y // 左下点与底部的距离
        translate.x *= -1 * scale * iScale
        translate.y *= -1 * scale * iScale
        
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        transform = transform.rotated(by: -radian)
        transform = transform.translatedBy(x: translate.x, y: translate.y)
        
        // 旋转+缩放+位移
        context.concatenate(transform)
        
        // 绘制
        context.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let newImageRef = context.makeImage() else { return nil }
        return UIImage(cgImage: newImageRef)
    }
}
