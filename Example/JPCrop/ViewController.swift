//
//  ViewController.swift
//  JPCrop
//
//  Created by Rogue24 on 12/26/2020.
//  Copyright (c) 2020 Rogue24. All rights reserved.
//

import UIKit
import JPCrop
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    lazy var configure: Croper.Configure? = {
        guard let image = imageView.image else { return nil }
        return Croper.Configure(image)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "JPCrop"
        
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 18.px, weight: .bold)
        ]
        
        imageView.layer.shadowRadius = 8
        imageView.layer.shadowOffset = CGSize(width: 0, height: 5)
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    
    func goCrop(_ configure: Croper.Configure) {
        guard let navCtr = navigationController else { return }
        
        let cropVC = CropViewController.build(configure) { [weak self] (image, configure) in
            guard let self = self else { return }
            self.configure = configure
            UIView.transition(with: self.imageView,
                              duration: 0.2,
                              options: .transitionCrossDissolve,
                              animations: {
                self.imageView.image = image
            }, completion: nil)
        }
        
        navCtr.pushViewController(cropVC, animated: true)
    }

}

extension ViewController {
    @IBAction func selectImage() {
        let alertCtr = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertCtr.addAction(UIAlertAction(title: "拍照", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            self.present(picker, animated: true, completion: nil)
        })
        
        alertCtr.addAction(UIAlertAction(title: "相册", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        })
        
        alertCtr.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alertCtr, animated: true, completion: nil)
    }
    
    @IBAction func backToCrop() {
        guard let configure = self.configure else {
            JPrint("当前没有可裁剪的图片")
            return
        }
        goCrop(configure)
    }
    
    @IBAction func saveToPhotoLibrary() {
        guard let image = imageView.image else {
            JPrint("当前没有可保存的图片")
            return
        }
        
        JPrint("正在保存...")
        DispatchQueue.global().async {
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            } catch { JPrint("保存失败：", error) }
            JPrint("保存成功")
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self,
                  var image = info[.originalImage] as? UIImage else { return }
            // 需要修正一下方向
            image = image.fixOrientation()
            
            let configure = Croper.Configure(image)
            self.goCrop(configure)
        }
    }
}
