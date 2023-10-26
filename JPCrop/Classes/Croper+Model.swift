//
//  Croper+Model.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/23.
//

import UIKit

// MARK: - 公开模型
public extension Croper {
    /// 网格数 - (垂直方向数量, 水平方向数量)
    typealias GridCount = (verCount: Int, horCount: Int)
    
    /// 旋转基准角度：0°/360°、90°、180°、270°
    enum OriginAngle: CGFloat {
        /// 以 0°/360° 为基准，可旋转范围：`-45° ~ 45°`
        case deg0 = 0
        
        /// 以 90° 为基准，可旋转范围：`45° ~ 135°`
        case deg90 = 90
        
        /// 以 180° 为基准，可旋转范围：`135° ~ 225°`
        case deg180 = 180
        
        /// 以 270° 为基准，可旋转范围：`225° ~ 315°`
        case deg270 = 270
        
        /// 上一个基准角度
        var prev: Self {
            switch self {
            case .deg0: return .deg270
            case .deg90: return .deg0
            case .deg180: return .deg90
            case .deg270: return .deg180
            }
        }
        
        /// 下一个基准角度
        var next: Self {
            switch self {
            case .deg0: return .deg90
            case .deg90: return .deg180
            case .deg180: return .deg270
            case .deg270: return .deg0
            }
        }
    }
    
    /// 初始化配置
    struct Configure {
        /// 裁剪图片
        public let image: UIImage
        
        /// 裁剪宽高比
        public let cropWHRatio: CGFloat
        
        /// 旋转基准角度：0°/360°、90°、180°、270°
        public var originAngle: Croper.OriginAngle
        
        /// 调整的旋转角度（基于`originAngle`，范围：`-45°` ~ `45°`）
        public var angle: CGFloat
        
        /// 裁剪时的缩放比例
        public var zoomScale: CGFloat?
        
        /// 裁剪时的偏移量
        public var contentOffset: CGPoint?
        
        public init(_ image: UIImage,
                    cropWHRatio: CGFloat = 0,
                    originAngle: Croper.OriginAngle = .deg0,
                    angle: CGFloat = 0,
                    zoomScale: CGFloat? = nil,
                    contentOffset: CGPoint? = nil) {
            self.image = image
            self.cropWHRatio = cropWHRatio
            self.originAngle = originAngle
            self.angle = angle
            self.zoomScale = zoomScale
            self.contentOffset = contentOffset
        }
    }
}

// MARK: - 私有模型
extension Croper {
    struct RotateFactor {
        let scale: CGFloat
        let transform: CGAffineTransform
        let contentInset: UIEdgeInsets
    }
    
    struct DiffFactor {
        let factor: RotateFactor
        let contentScalePoint: CGPoint
        let zoomScale: CGFloat
        let imageFrameSize: CGSize
    }
    
    struct CropFactor {
        let cropWHRatio: CGFloat
        let scale: CGFloat
        let convertTranslate: CGPoint
        let radian: CGFloat
        let imageBoundsHeight: CGFloat
    }
}
