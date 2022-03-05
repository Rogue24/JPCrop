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
    @IBOutlet weak var whRatioBtn: UIButton!
    @IBOutlet weak var slider: UISlider!
    
    typealias CropDone = (UIImage?, Croper.Configure) -> ()
    
    var croper: Croper!
    var configure: Croper.Configure?
    var cropDone: CropDone?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let configure = self.configure else {
            JPrint("图片不存在")
            return
        }
        
        let croperFrame = CGRect(x: 0, y: StatusBarH, width: PortraitScreenWidth,
                                 height: PortraitScreenHeight - StatusBarH - DiffTabBarH - 100)
        
        let croper = Croper(frame: croperFrame, configure)
        view.insertSubview(croper, at: 0)
        self.croper = croper
        
        croper.cropWHRatioRangeOverstep = { (isUpper, _) in
            if isUpper {
                JPrint("最大裁剪宽高比是 2 : 1")
            } else {
                JPrint("最小裁剪宽高比是 3 : 4")
            }
        }
        
        slider.minimumValue = -Float(Croper.diffAngle)
        slider.maximumValue = Float(Croper.diffAngle)
        slider.value = Float(configure.angle)
        
        slider.addTarget(self, action: #selector(beginSlider), for: .touchDown)
        slider.addTarget(self, action: #selector(sliding), for: .valueChanged)
        slider.addTarget(self, action: #selector(endSlider), for: .touchCancel)
        slider.addTarget(self, action: #selector(endSlider), for: .touchUpInside)
        slider.addTarget(self, action: #selector(endSlider), for: .touchUpOutside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

extension CropViewController {
    static func build(_ configure: Croper.Configure, cropDone: CropDone?) -> Self {
        let cropVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CropViewController") as! Self
        cropVC.configure = configure
        cropVC.cropDone = cropDone
        return cropVC
    }
}

// MARK: - 监听裁剪/恢复/裁剪事件
extension CropViewController {
    @IBAction func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func recover() {
        croper.recover(animated: true)
        slider.setValue(0, animated: true)
    }
    
    @IBAction func crop() {
//        guard let image = croper.crop() else { return }
//        cropDone?(image, croper.syncConfigure())
        
        navigationController?.popViewController(animated: true)
        
        guard let cropDone = self.cropDone else { return }
        let configure = croper.syncConfigure()
        
        croper.asyncCrop {
            guard let image = $0 else { return }
            cropDone(image, configure)
        }
    }
}

// MARK: - 监听比例切换事件
extension CropViewController {
    @IBAction func switchWHRatio() {
        let alertCtr = UIAlertController(title: "切换裁剪宽高比", message: nil, preferredStyle: .actionSheet)
        
        alertCtr.addAction(UIAlertAction(title: "原始", style: .default) { _ in
            self.croper.updateCropWHRatio(0, rotateGridCount: (5, 5), animated: true)
            self.whRatioBtn.setTitle("原始", for: .normal)
        })
        
        alertCtr.addAction(UIAlertAction(title: "9 : 16", style: .default) { _ in
            self.croper.updateCropWHRatio(9.0 / 16.0, rotateGridCount: (6, 5), animated: true)
            self.whRatioBtn.setTitle("9 : 16", for: .normal)
        })
        
        alertCtr.addAction(UIAlertAction(title: "1 : 1", style: .default) { _ in
            self.croper.updateCropWHRatio(1, rotateGridCount: (4, 4), animated: true)
            self.whRatioBtn.setTitle("1 : 1", for: .normal)
        })
        
        alertCtr.addAction(UIAlertAction(title: "4 : 3", style: .default) { _ in
            self.croper.updateCropWHRatio(4.0 / 3.0, rotateGridCount: (4, 5), animated: true)
            self.whRatioBtn.setTitle("4 : 3", for: .normal)
        })
        
        alertCtr.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alertCtr, animated: true, completion: nil)
    }
    
    @IBAction func rotate2Right() {
        croper.rotateRight(animated: true)
    }
    
    @IBAction func rotate2Left() {
        croper.rotateLeft(animated: true)
    }
}

// MARK: - 监听Slider（旋转）
extension CropViewController {
    @objc func beginSlider() {
        croper.showRotateGrid(animated: true)
    }
    
    @objc func sliding() {
        let angle = CGFloat(slider.value)
        croper.rotate(angle)
    }
    
    @objc func endSlider() {
        croper.hideRotateGrid(animated: true)
    }
}
