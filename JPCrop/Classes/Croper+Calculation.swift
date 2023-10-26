//
//  Croper+Calculation.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/26.
//

import UIKit

extension Croper {
    func scaleValue(_ t: CGAffineTransform) -> CGFloat {
        sqrt(t.a * t.a + t.c * t.c)
    }
    
    func fitCropWHRatio(_ cropWHRatio: CGFloat, isCallBack: Bool = false) -> CGFloat {
        if cropWHRatio <= 0 {
            return 0
        }
        
        let range = Self.cropWHRatioRange
        if range.contains(cropWHRatio) {
            return cropWHRatio
        }
        
        let isUpper = cropWHRatio > range.upperBound
        let bound = isUpper ? range.upperBound : range.lowerBound
        
        if isCallBack, let overstep = cropWHRatioRangeOverstep {
            overstep(isUpper, bound)
        }
        
        return bound
    }
    
    func fitAngle(_ angle: CGFloat) -> CGFloat {
        switch angle {
        case ...angleRange.lowerBound:
            return angleRange.lowerBound
        case angleRange.upperBound...:
            return angleRange.upperBound
        default:
            return angle
        }
    }
    
    func fitCropFrame() -> CGRect {
        let margin = Self.margin
        let maxW = bounds.width - margin.left - margin.right
        let maxH = bounds.height - margin.top - margin.bottom
        let whRatio = cropWHRatio > 0 ? cropWHRatio : fitCropWHRatio(imageWHRatio)
        
        var w = maxW
        var h = w / whRatio
        if h > maxH {
            h = maxH
            w = h * whRatio
        }
        
        let x = (maxW - w) * 0.5 + margin.left
        let y = (maxH - h) * 0.5 + margin.top
        
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    func fitImageSize() -> CGSize {
        var imageW: CGFloat
        var imageH: CGFloat
        
        if isLandscapeImage {
            imageH = cropFrame.height
            imageW = imageH * imageWHRatio
            if imageW < cropFrame.width {
                imageW = cropFrame.width
                imageH = imageW / imageWHRatio
            }
        } else {
            imageW = cropFrame.width
            imageH = imageW / imageWHRatio
            if imageH < cropFrame.height {
                imageH = cropFrame.height
                imageW = imageH * imageWHRatio
            }
        }
        
        return CGSize(width: imageW, height: imageH)
    }
    
    func fitFactor() -> RotateFactor {
        let imageW = imageBoundsSize.width
        let imageH = imageBoundsSize.height
        
        let cropW = cropFrame.width
        let cropH = cropFrame.height
        
        let actualRadian = self.actualRadian
        let absRadian = fabs(Double(actualRadian))
        let cosValue = CGFloat(fabs(cos(absRadian)))
        let sinValue = CGFloat(fabs(sin(absRadian)))
        
        let verSide1 = cosValue * cropH
        let verSide2 = sinValue * cropW
        let verSide = verSide1 + verSide2
        
        let horSide1 = cosValue * cropW
        let horSide2 = sinValue * cropH
        let horSide = horSide1 + horSide2
        
        let scale: CGFloat
        if imageW > cropW || imageH > cropH {
            if cropW > cropH {
                let scale1 = verSide / imageH
                let scale2 = horSide / cropW
                scale = max(scale1, scale2)
            } else {
                let scale1 = horSide / imageW
                let scale2 = verSide / cropH
                scale = max(scale1, scale2)
            }
        } else {
            if isLandscapeImage {
                scale = verSide / cropH
            } else {
                scale = horSide / cropW
            }
        }
        
        let verMargin = (cropH * scale - verSide) * 0.5 / scale
        let horMargin = (cropW * scale - horSide) * 0.5 / scale
        
        let top = verMargin + minMargin.top
        let left = horMargin + minMargin.left
        let bottom = verMargin + minMargin.bottom
        let right = horMargin + minMargin.right
        
        let transform = CGAffineTransform(rotationAngle: actualRadian).scaledBy(x: scale, y: scale)
        let contentInset = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
        
        return RotateFactor(scale: scale, transform: transform, contentInset: contentInset)
    }
    
    func fitOffset(_ contentScalePoint: CGPoint, contentSize: CGSize? = nil, contentInset: UIEdgeInsets? = nil) -> CGPoint {
        let sBounds = scrollView.bounds
        let size = contentSize ?? scrollView.contentSize
        
        var offsetX = contentScalePoint.x * size.width - sBounds.width * scrollView.layer.anchorPoint.x
        var offsetY = contentScalePoint.y * size.height - sBounds.height * scrollView.layer.anchorPoint.y
        
        guard let insets = contentInset else {
            return CGPoint(x: offsetX, y: offsetY)
        }
        
        let maxOffsetX = size.width - sBounds.width + insets.right
        let maxOffsetY = size.height - sBounds.height + insets.bottom
        
        if offsetX < -insets.left {
            offsetX = -insets.left
        } else if offsetX > maxOffsetX {
            offsetX = maxOffsetX
        }
        
        if offsetY < -insets.top {
            offsetY = -insets.top
        } else if offsetY > maxOffsetY {
            offsetY = maxOffsetY
        }
        
        return CGPoint(x: offsetX, y: offsetY)
    }
}

