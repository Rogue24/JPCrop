//
//  Croper.swift
//  JPCrop_Example
//
//  Created by 周健平 on 2020/12/21.
//

import UIKit

public class Croper: UIView {
    
    // MARK: - 默认初始值
    
    /// 裁剪区域的边距
    public static var margin: CGFloat = 15
    
    /// 动画时间
    public static var animDuration: TimeInterval = 0.3
    
    /// 裁剪宽高比的范围（默认 最小 `1 : 2` ~ `2 : 1`）
    public static var cropWHRatioRange: ClosedRange<CGFloat> = (1.0 / 2.0) ... 2.0
    
    /// 可旋转的范围角度：`-45°` ~ `45°`
    public static let diffAngle: CGFloat = 45.0
    
    // MARK: - 公开属性
    
    /// 裁剪图片
    public let image: UIImage
    
    /// 图片的宽高比（当`cropWHRatio = 0`时取该值）
    public let imageWHRatio: CGFloat
    
    /// 图片视图基于并适配`cropFrame`的`size`
    public internal(set) var imageBoundsSize: CGSize = .zero
    
    /// 裁剪宽高比
    public internal(set) var cropWHRatio: CGFloat = 0
    
    /// 裁剪框的frame
    public internal(set) var cropFrame: CGRect = .zero
    
    /// 旋转基准角度：`0°/360°、90°、180°、270°`
    public internal(set) var originAngle: OriginAngle = .deg0
    
    /// 可旋转角度范围（基于`originAngle`，范围：`-45°` ~ `45°`）
    public var angleRange: ClosedRange<CGFloat> {
        (originAngle.rawValue - Self.diffAngle) ... (originAngle.rawValue + Self.diffAngle)
    }
    
    /// 当前实际的旋转角度（范围：`0°` ~ `360°`）
    public internal(set) var actualAngle: CGFloat = OriginAngle.deg0.rawValue
    
    /// 当前调整的旋转角度（基于`originAngle`，范围：`-45°` ~ `45°`）
    public internal(set) var angle: CGFloat {
        set { actualAngle = fitAngle(originAngle.rawValue + newValue) }
        get { actualAngle - originAngle.rawValue }
    }
    
    /// 当前实际的旋转弧度（范围：`0` ~ `2π`）
    public var actualRadian: CGFloat { (actualAngle / 180.0) * CGFloat.pi }
    
    /// 当前调整的旋转弧度（基于`originAngle`，范围：`-π/4` ~ `π/4`）
    public var radian: CGFloat { (angle / 180.0) * CGFloat.pi }
    
    /// 类型：网格数 - (垂直方向数量, 水平方向数量)
    public typealias GridCount = (verCount: Int, horCount: Int)
    
    /// 闲置时的网格数
    public var idleGridCount: GridCount = (0, 0)
    
    /// 旋转时的网格数
    public var rotateGridCount: GridCount = (0, 0)
    
    /// 当设置裁剪宽高比时超出可设置范围时的回调
    public var cropWHRatioRangeOverstep: ((_ isUpper: Bool, _ bound: CGFloat) -> ())?
    
    // MARK: - 私有属性
    var minHorMargin: CGFloat = 0
    var minVerMargin: CGFloat = 0
    
    let scrollView = UIScrollView()
    let imageView = UIImageView()
    let shadeLayer = CAShapeLayer()
    let borderLayer = CAShapeLayer()
    let idleGridLayer = CAShapeLayer()
    let rotateGridLayer = CAShapeLayer()
    
    // MARK: - 构造器
    public convenience init(frame: CGRect,
                            _ configure: Configure,
                            idleGridCount: GridCount = (3, 3),
                            rotateGridCount: GridCount = (5, 5)) {
        self.init(frame: frame,
                  configure.image,
                  configure.cropWHRatio,
                  configure.originAngle,
                  configure.angle,
                  configure.zoomScale,
                  configure.contentOffset,
                  idleGridCount,
                  rotateGridCount)
    }
    
    public init(frame: CGRect = UIScreen.main.bounds,
                _ image: UIImage,
                _ cropWHRatio: CGFloat,
                _ originAngle: OriginAngle,
                _ angle: CGFloat,
                _ zoomScale: CGFloat? = nil,
                _ contentOffset: CGPoint? = nil,
                _ idleGridCount: GridCount? = nil,
                _ rotateGridCount: GridCount? = nil) {
        
        self.image = image
        self.imageWHRatio = image.size.width / image.size.height
        self.originAngle = originAngle
        
        super.init(frame: frame)
        
        setupUI()
        updateCropWHRatio(cropWHRatio, idleGridCount: idleGridCount, rotateGridCount: rotateGridCount)
        rotate(angle)
        
        if let scale = zoomScale { scrollView.zoomScale = scale }
        if let offset = contentOffset { scrollView.contentOffset = offset }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { scrollView }
}

// MARK: - UIScrollViewDelegate
extension Croper: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}

// MARK: - 私有API
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
        UIView.animate(withDuration: Self.animDuration) {
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
