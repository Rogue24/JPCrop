//
//  Calculation.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/26.
//

import UIKit

extension Croper {
    func fitCropWHRatio(_ cropWHRatio: CGFloat, isCallBack: Bool = false) -> CGFloat {
        let range = Self.cropWHRatioRange
        
        if cropWHRatio < range.lowerBound {
            if isCallBack, let overstep = cropWHRatioRangeOverstep {
                overstep(false, range.lowerBound)
            }
            
            return cropWHRatio <= 0 ? 0 : range.lowerBound
        }
        
        if cropWHRatio > range.upperBound {
            if isCallBack, let overstep = cropWHRatioRangeOverstep {
                overstep(true, range.upperBound)
            }
            
            return range.upperBound
        }
        
        return cropWHRatio
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
        let maxW = bounds.width - margin * 2
        let maxH = bounds.height - margin * 2
        let whRatio = cropWHRatio > 0 ? cropWHRatio : fitCropWHRatio(imageWHRatio)
        
        var w = maxW
        var h = w / whRatio
        if h > maxH {
            h = maxH
            w = h * whRatio
        }
        
        let x = margin + (maxW - w) * 0.5
        let y = margin + (maxH - h) * 0.5
        
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
    
    func fitFactor() -> (scale: CGFloat, transform: CGAffineTransform, contentInset: UIEdgeInsets) {
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
        
        let verMargin = (cropH * scale - verSide) * 0.5 / scale + minVerMargin
        let horMargin = (cropW * scale - horSide) * 0.5 / scale + minHorMargin
        
        return (scale,
                CGAffineTransform(rotationAngle: actualRadian).scaledBy(x: scale, y: scale),
                UIEdgeInsets(top: verMargin, left: horMargin, bottom: verMargin, right: horMargin))
    }
    
    func fitOffset(_ xSclae: CGFloat, _ ySclae: CGFloat, contentSize: CGSize? = nil, contentInset: UIEdgeInsets? = nil) -> CGPoint {
        let sBounds = scrollView.bounds
        let size = contentSize ?? scrollView.contentSize
        
        var offsetX = xSclae * size.width - sBounds.width * 0.5
        var offsetY = ySclae * size.height - sBounds.height * 0.5
        
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
