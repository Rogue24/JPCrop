//
//  Builder.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/23.
//

import UIKit

extension Croper {
    func setupUI() {
        clipsToBounds = true
        backgroundColor = .black
        
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        if #available(iOS 11.0, *) { scrollView.contentInsetAdjustmentBehavior = .never }
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
    
    
    func buildAnimation<T>(addTo layer: CALayer, _ keyPath: String, _ toValue: T, _ duration: TimeInterval, timingFunctionName: CAMediaTimingFunctionName = .easeOut) {
        let anim = CABasicAnimation(keyPath: keyPath)
        anim.fromValue = layer.value(forKeyPath: keyPath)
        anim.toValue = toValue
        anim.fillMode = .backwards
        anim.duration = duration
        anim.timingFunction = CAMediaTimingFunction(name: timingFunctionName)
        layer.add(anim, forKey: keyPath)
    }
}

