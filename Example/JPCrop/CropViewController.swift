//
//  CropViewController.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import JPCrop

class CropViewController: UIViewController {
    typealias CropDone = (UIImage?, Croper.Configure) -> ()
    
    private var configure: Croper.Configure!
    private var croper: Croper!
    private var cropDone: CropDone?
    
    private let operationBar = UIView()
    
    private var slider: CropSlider!
    private let stackView = UIStackView()
    
    private var ratioBar: CropRatioBar?
    private lazy var ratio: CGSize = configure.image.size
    
    static func build(_ configure: Croper.Configure, cropDone: CropDone?) -> CropViewController {
        let cropVC = CropViewController()
        cropVC.configure = configure
        cropVC.cropDone = cropDone
        return cropVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBase()
        setupOperationBar()
        setupCroper()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

private extension CropViewController {
    func setupBase() {
        view.clipsToBounds = true
        view.backgroundColor = .black
    }
    
    func setupOperationBar() {
        let h = 50.px + NavBarH + DiffTabBarH
        
        operationBar.frame = CGRect(x: 0, y: PortraitScreenHeight - h, width: PortraitScreenWidth, height: h)
        view.addSubview(operationBar)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = operationBar.bounds
        operationBar.addSubview(blurView)
        
        let slider = CropSlider(minimumValue: -Float(Croper.diffAngle), maximumValue: Float(Croper.diffAngle), value: 0)
        slider.frame.origin.y = 10.px
        slider.sliderWillChangedForUser = { [weak self] in
            guard let self = self else { return }
            self.croper.showRotateGrid(animated: true)
        }
        slider.sliderDidChangedForUser = { [weak self] value in
            guard let self = self else { return }
            self.croper.rotate(value)
        }
        slider.sliderEndChangedForUser = { [weak self] in
            guard let self = self else { return }
            self.croper.hideRotateGrid(animated: true)
        }
        operationBar.addSubview(slider)
        self.slider = slider
        
        stackView.backgroundColor = .clear
        stackView.frame = CGRect(x: 0, y: 50.px, width: PortraitScreenWidth, height: NavBarH)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        operationBar.addSubview(stackView)
        
        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBtn.tintColor = .white
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(backBtn)
        
        let rotateBtn = UIButton(type: .system)
        rotateBtn.setImage(UIImage(systemName: "rotate.left"), for: .normal)
        rotateBtn.tintColor = .white
        rotateBtn.addTarget(self, action: #selector(rotateLeft), for: .touchUpInside)
        rotateBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(rotateBtn)
        
        let ratioBtn = UIButton(type: .system)
        ratioBtn.setImage(UIImage(systemName: "aspectratio"), for: .normal)
        ratioBtn.tintColor = .white
        ratioBtn.addTarget(self, action: #selector(switchRatio), for: .touchUpInside)
        ratioBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(ratioBtn)
        
        let recoverBtn = UIButton(type: .system)
        recoverBtn.setImage(UIImage(systemName: "gobackward"), for: .normal)
        recoverBtn.tintColor = .white
        recoverBtn.addTarget(self, action: #selector(recover), for: .touchUpInside)
        recoverBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(recoverBtn)
        
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.titleLabel?.font = .systemFont(ofSize: 15.px, weight: .bold)
        doneBtn.addTarget(self, action: #selector(crop), for: .touchUpInside)
        doneBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(doneBtn)
    }
    
    func setupCroper() {
        Croper.margin = UIEdgeInsets(top: StatusBarH + 15.px,
                                     left: 15.px,
                                     bottom: 50.px + NavBarH + DiffTabBarH + 15.px,
                                     right: 15.px)
        let croper = Croper(frame: PortraitScreenBounds, configure: configure)
        croper.clipsToBounds = false
        view.insertSubview(croper, at: 0)
        self.croper = croper
    }
}

// MARK: - 监听返回/恢复/旋转/比例切换/裁剪事件
private extension CropViewController {
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func rotateLeft() {
        croper.rotateLeft(animated: true)
    }
    
    @objc func switchRatio() {
        showRatioBar()
    }
    
    @objc func recover() {
        croper.recover(animated: true)
        slider.updateValue(0, animated: true)
    }
    
    @objc func crop() {
        navigationController?.popViewController(animated: true)
        
        guard let cropDone = self.cropDone else { return }
        
        DispatchQueue.global().async {
            guard let image = self.croper.crop() else {
                JPrint("裁剪失败！")
                return
            }
            
            let configure = self.croper.getCurrentConfigure()
            DispatchQueue.main.async {
                cropDone(image, configure)
            }
        }
    }
}

extension CropViewController {
    func showRatioBar() {
        guard self.ratioBar == nil else { return }
        
        let ratioBar = CropRatioBar(imageSize: configure.image.size, ratio: ratio) { [weak self] ratio in
            guard let self = self else { return }
            self.ratio = ratio
            self.croper.updateCropWHRatio(ratio.width / ratio.height, animated: true)
        } closeHandler: { [weak self] in
            self?.hideRatioBar()
        }
        ratioBar.alpha = 0
        ratioBar.frame.origin.y = operationBar.frame.height * 0.3
        operationBar.addSubview(ratioBar)
        self.ratioBar = ratioBar
        
        let diffH = operationBar.frame.height * 0.3
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            self.slider.frame.origin.y += diffH
            self.slider.alpha = 0
            self.stackView.frame.origin.y += diffH
            self.stackView.alpha = 0
        }
        
        UIView.animate(withDuration: 0.45, delay: 0.1, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            ratioBar.frame.origin.y = 0
            ratioBar.alpha = 1
        }
    }
    
    func hideRatioBar() {
        guard let ratioBar = self.ratioBar else { return }
        self.ratioBar = nil
        
        let diffH = operationBar.frame.height * 0.3
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            ratioBar.frame.origin.y = diffH
            ratioBar.alpha = 0
        } completion: { _ in
            ratioBar.removeFromSuperview()
        }
        
        UIView.animate(withDuration: 0.45, delay: 0.1, usingSpringWithDamping: 0.9, initialSpringVelocity: 1) {
            self.slider.frame.origin.y -= diffH
            self.slider.alpha = 1
            self.stackView.frame.origin.y -= diffH
            self.stackView.alpha = 1
        }
    }
}
