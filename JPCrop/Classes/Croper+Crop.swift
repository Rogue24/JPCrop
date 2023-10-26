//
//  Croper+Crop.swift
//  JPCrop
//
//  Created by Rogue24 on 2022/3/5.
//

import UIKit

extension Croper {
    func getCropFactorSafely() -> CropFactor {
        var ratio: CGFloat = 0
        var scale: CGFloat = 0
        var translate: CGPoint = .zero
        var radian: CGFloat = 0
        var height: CGFloat = 0
        
        Self.executeInMainQueue {
            ratio = self.cropWHRatio > 0 ? self.cropWHRatio : self.fitCropWHRatio(self.imageWHRatio)
            scale = self.scaleValue(self.scrollView.transform) * self.scrollView.zoomScale
            translate = self.borderLayer.convert(CGPoint(x: self.cropFrame.origin.x, y: self.cropFrame.maxY), to: self.imageView.layer)
            radian = self.actualRadian
            height = self.imageView.bounds.height
        }
        
        return CropFactor(cropWHRatio: ratio,
                          scale: scale,
                          convertTranslate: translate,
                          radian: radian,
                          imageBoundsHeight: height)
    }
    
    static func crop(_ compressScale: CGFloat,
                     _ imageRef: CGImage,
                     _ factor: CropFactor) -> UIImage? {
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
        
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)
        context.interpolationQuality = .high
        // 旋转+缩放+位移
        context.concatenate(transform)
        // 绘制
        context.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let newImageRef = context.makeImage() else { return nil }
        return UIImage(cgImage: newImageRef)
    }
}
