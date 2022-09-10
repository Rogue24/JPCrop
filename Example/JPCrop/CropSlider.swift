//
//  CropSlider.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2022/4/26.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import pop

class CropSlider: UIView {
    private let bgLayer = ScaleLayer()
    private let slider = UISlider()
    private var valueLabel: UILabel?
    private var hideWorkItem: DispatchWorkItem? = nil
    private var thumbView: UIView? = nil
    
    var sliderWillChangedForUser: (() -> ())?
    var sliderDidChangedForUser: ((CGFloat) -> ())?
    var sliderEndChangedForUser: (() -> ())?
    
    init(minimumValue: Float, maximumValue: Float, value: Float) {
        super.init(frame: CGRect(x: 0, y: 0, width: PortraitScreenWidth, height: 40.px))
        
        bgLayer.position = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
        layer.addSublayer(bgLayer)
        
        slider.maximumTrackTintColor = .clear
        slider.minimumTrackTintColor = .clear
        slider.frame.size = CGSize(width: bgLayer.frame.width + 4, height: frame.height)
        slider.center = CGPoint(x: frame.width * 0.5, y: frame.height * 0.5)
        addSubview(slider)
        
        let thumb = UIView(frame: CGRect(x: 0, y: 0, width: 3.px, height: 20.px))
        thumb.layer.cornerRadius = 1.5.px
        thumb.layer.masksToBounds = true
        thumb.backgroundColor = .systemBlue
        UIGraphicsBeginImageContextWithOptions(thumb.frame.size, false, ScreenScale)
        thumb.layer.render(in: UIGraphicsGetCurrentContext()!)
        let thumbImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        slider.setThumbImage(thumbImage, for: .normal)
        
        slider.addTarget(self, action: #selector(sliderBegin), for: .touchDown)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderEnd), for: .touchCancel)
        slider.addTarget(self, action: #selector(sliderEnd), for: .touchUpInside)
        slider.addTarget(self, action: #selector(sliderEnd), for: .touchUpOutside)
        
        slider.minimumValue = minimumValue
        slider.maximumValue = maximumValue
        slider.value = value
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        hideWorkItem?.cancel()
        thumbView?.removeObserver(self, forKeyPath: "frame")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let valueLabel = self.valueLabel, let thumbView = self.thumbView else { return }
        valueLabel.center.x = thumbView.center.x
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event) else { return nil }
        return slider
    }
    
    private var isShowValue = false {
        didSet {
            guard let thumbView = slider.value(forKeyPath: "_thumbView") as? UIView else { return }
            if let kThumbView = self.thumbView, kThumbView != thumbView {
                kThumbView.removeObserver(self, forKeyPath: "frame")
                self.thumbView = nil
            }
            if self.thumbView == nil {
                thumbView.addObserver(self, forKeyPath: "frame", context: nil)
                self.thumbView = thumbView
            }
            
            defer {
                if isShowValue {
                    valueLabel?.text = "\(String(format: "%.0f°", slider.value))"
                }
            }
            
            guard isShowValue != oldValue else { return }
            hideWorkItem?.cancel()
            hideWorkItem = nil
            
            if !isShowValue {
                if let valueLabel = self.valueLabel {
                    let workItem = DispatchWorkItem { [weak valueLabel] in
                        guard let label = valueLabel else { return }
                        let anim = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
                        anim.duration = 0.25
                        anim.toValue = 0
                        label.pop_add(anim, forKey: kPOPViewAlpha)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
                    hideWorkItem = workItem
                }
                return
            }
            
            let valueLabel = self.valueLabel ?? {
                let valueLabel =  UILabel()
                valueLabel.textAlignment = .center
                valueLabel.font = .systemFont(ofSize: 11.px)
                valueLabel.textColor = .white
                valueLabel.frame = CGRect(x: 0, y: slider.frame.origin.y - 7.px, width: 50.px, height: 15.px)
                valueLabel.alpha = 0
                slider.addSubview(valueLabel)
                self.valueLabel = valueLabel
                return valueLabel
            }()
            valueLabel.center.x = thumbView.center.x
            
            let anim = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
            anim.duration = 0.25
            anim.toValue = 1
            valueLabel.pop_add(anim, forKey: kPOPViewAlpha)
        }
    }
    
    var isShowSlider = true {
        didSet {
            guard isShowSlider != oldValue else { return }
            let anim = POPBasicAnimation(propertyNamed: kPOPViewAlpha)!
            anim.duration = 0.2
            anim.toValue = isShowSlider ? 1 : 0
            slider.pop_add(anim, forKey: kPOPViewAlpha)
            
            let anim2 = POPBasicAnimation(propertyNamed: kPOPLayerOpacity)!
            anim2.duration = 0.2
            anim2.toValue = isShowSlider ? 1 : 0.6
            bgLayer.pop_add(anim2, forKey: kPOPLayerOpacity)
            
            if isShowSlider {
                isShowValue = true
                isShowValue = false
            }
        }
    }
    
    var value: CGFloat {
        set { slider.value = Float(newValue) }
        get { CGFloat(slider.value) }
    }
    
    func updateValue(_ value: CGFloat, animated: Bool) {
        slider.setValue(Float(value), animated: animated)
        isShowValue = true
        isShowValue = false
    }
}

extension CropSlider {
    @objc func sliderBegin() {
        isShowValue = true
        sliderWillChangedForUser?()
    }

    @objc func sliderChanged() {
        isShowValue = true
        sliderDidChangedForUser?(value)
    }
    
    @objc func sliderEnd() {
        isShowValue = false
        sliderEndChangedForUser?()
    }
}

extension CropSlider {
    class ScaleLayer: CALayer {
        override init() {
            super.init()
            frame = CGRect(x: 0, y: 0, width: PortraitScreenWidth - 40.px, height: 12.px)
            
            let space = frame.width / 50
            for i in 0 ... 50 {
                let line = CALayer()
                line.backgroundColor = UIColor(white: 1, alpha: i % 10 == 0 ? 1 : 0.4).cgColor
                line.frame = CGRect(x: 0, y: 0, width: i % 10 == 0 ? 1.5.px : 1.px, height: frame.height)
                line.position = CGPoint(x: CGFloat(i) * space, y: frame.height * 0.5)
                addSublayer(line)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
