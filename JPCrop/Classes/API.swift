//
//  API.swift
//  JPCrop
//
//  Created by aa on 2022/3/5.
//

// MARK: - 公开API
public extension Croper {
    
    // MARK: 获取同步的Configure（当前的裁剪元素、状态）
    /// 获取同步的Configure，可用于保存当前的裁剪状态，下一次打开恢复状态
    func syncConfigure() -> Configure {
        Configure(image,
                  cropWHRatio: cropWHRatio,
                  originAngle: originAngle,
                  angle: angle,
                  zoomScale: scrollView.zoomScale,
                  contentOffset: scrollView.contentOffset)
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
        self.cropWHRatio = fitCropWHRatio(cropWHRatio, isCallBack: true)
        
        let oldCropFrame = cropFrame
        cropFrame = fitCropFrame()
        minHorMargin = (bounds.width - cropFrame.width) * 0.5
        minVerMargin = (bounds.height - cropFrame.height) * 0.5
        
        // 1.算出改变后的UI数值，和改变前后的差值
        
        // 获取 imageView 基于并适配 cropFrame 的原始 Size
        imageBoundsSize = fitImageSize()
        // 获取 scrollView 最合适（不会超出）cropFrame 和 radian 的 transform 和 contentInset
        let factor = fitFactor()
        
        let zoomScale: CGFloat
        let xScale: CGFloat
        let yScale: CGFloat
        if imageView.bounds.width > 0 {
            let fromPoint = CGPoint(x: oldCropFrame.midX, y: oldCropFrame.midY)
            let convertOffset = borderLayer.convert(fromPoint, to: imageView.layer)
            xScale = convertOffset.x / imageView.bounds.width
            yScale = convertOffset.y / imageView.bounds.height
            
            let diffScale = scaleValue(scrollView.transform) / scaleValue(factor.transform)
            zoomScale = imageView.frame.width / imageBoundsSize.width * diffScale
        } else {
            xScale = 0.5
            yScale = 0.5
            zoomScale = 1
        }
        
        let imageFrameSize = CGSize(width: imageBoundsSize.width * zoomScale,
                                    height: imageBoundsSize.height * zoomScale)
        
        // 2.立马设置 scrollView 改变后的 transform，和其他的一些差值，让 scrollView 形变后相对于之前的 UI 状态“看上去”没有变化一样
        
        imageView.bounds = CGRect(origin: .zero, size: imageBoundsSize)
        
        scrollView.transform = factor.transform
        if zoomScale < 1 { scrollView.minimumZoomScale = zoomScale }
        scrollView.zoomScale = zoomScale
        scrollView.contentSize = imageFrameSize
        
        imageView.frame = CGRect(origin: .zero, size: imageFrameSize)
        
        scrollView.contentOffset = fitOffset(xScale, yScale, contentSize: imageFrameSize)
        
        // 3.再通过动画适配当前窗口，也就是把差值还原回去
        
        let updateScrollView = {
            if zoomScale < 1 {
                self.scrollView.minimumZoomScale = 1
                self.scrollView.zoomScale = 1
            }
            self.scrollView.contentInset = factor.contentInset
            self.scrollView.contentOffset = self.fitOffset(xScale, yScale, contentInset: factor.contentInset)
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
    
    // MARK: 显示旋转网格
    /// 显示旋转时的网格数
    func showRotateGrid(animated: Bool = false) {
        updateGrid(0, 1, animated: animated)
    }
    
    // MARK: 隐藏旋转网格
    /// 隐藏旋转时的网格数
    func hideRotateGrid(animated: Bool = false) {
        updateGrid(1, 0, animated: animated)
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
            self.scrollView.contentOffset = self.fitOffset(0.5, 0.5, contentInset: factor.contentInset)
        }
        if animated {
            UIView.animate(withDuration: Self.animDuration, delay: 0, options: .curveEaseOut, animations: updateScrollView, completion: nil)
        } else {
            updateScrollView()
        }
    }
    
    // MARK: 同步裁剪
    /// 同步裁剪
    /// - Parameters:
    ///   - compressScale: 压缩比例，默认为1，即原图尺寸
    func crop(_ compressScale: CGFloat = 1) -> UIImage? {
        guard let imageRef = image.cgImage else { return nil }
        
        let fromPoint = CGPoint(x: cropFrame.origin.x, y: cropFrame.maxY)
        let convertTranslate = borderLayer.convert(fromPoint, to: imageView.layer)
        
        return Self.crop(compressScale,
                         imageRef,
                         cropWHRatio > 0 ? cropWHRatio : fitCropWHRatio(imageWHRatio),
                         scaleValue(scrollView.transform) * scrollView.zoomScale,
                         convertTranslate,
                         actualRadian,
                         imageView.bounds.height)
    }
    
    // MARK: 异步裁剪
    /// 异步裁剪
    /// - Parameters:
    ///   - compressScale: 压缩比例，默认为1，即原图尺寸
    func asyncCrop(_ compressScale: CGFloat = 1, _ cropDone: @escaping (UIImage?) -> ()) {
        guard let imageRef = image.cgImage else {
            cropDone(nil)
            return
        }
        
        let cropWHRatio = self.cropWHRatio > 0 ? self.cropWHRatio : fitCropWHRatio(imageWHRatio)
        let scale = scaleValue(scrollView.transform) * scrollView.zoomScale
        let convertTranslate = borderLayer.convert(CGPoint(x: cropFrame.origin.x, y: cropFrame.maxY), to: imageView.layer)
        let radian = actualRadian
        let height = imageView.bounds.height
        
        DispatchQueue.global().async {
            let result = Self.crop(compressScale,
                                   imageRef,
                                   cropWHRatio,
                                   scale,
                                   convertTranslate,
                                   radian,
                                   height)
            DispatchQueue.main.async { cropDone(result) }
        }
    }
}
