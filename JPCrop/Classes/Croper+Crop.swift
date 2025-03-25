//
//  Croper+Crop.swift
//  JPCrop
//
//  Created by Rogue24 on 2022/3/5.
//

import UIKit

extension Croper {
    /// 获取修正方向后的图片
    func getFixedImageRef() -> CGImage? {
        let orientation = image.imageOrientation
        let imageRef = image.cgImage
        guard orientation != .up, let imageRef else { return imageRef }
        
        var transform = CGAffineTransform.identity
        
        switch orientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: -.pi / 2)
            
        default:
            break
        }
        
        switch orientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break
        }
        
        guard let context = CGContext(data: nil,
                                      width: Int(image.size.width),
                                      height: Int(image.size.height),
                                      bitsPerComponent: imageRef.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: imageRef.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: imageRef.bitmapInfo.rawValue) else {
            return imageRef
        }
        
        let drawRect: CGRect
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            drawRect =  CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
        default:
            drawRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        }
        
        context.concatenate(transform)
        context.draw(imageRef, in: drawRect)
        
        return context.makeImage() ?? imageRef
    }
    
    /// 获取裁剪参数
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
}
