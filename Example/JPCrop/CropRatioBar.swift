//
//  CropRatioBar.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2023/4/13.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit

class CropRatioBar: UIView {
    static let verRatios: [CGSize] = [[9, 16], [4, 5], [5, 7], [3, 4], [3, 5], [2, 3]]
    
    let imageSize: CGSize
    var ratio: CGSize = .zero {
        didSet {
            guard ratio != oldValue else { return }
            selectedHandler(ratio)
            updateBtnImage()
        }
    }
    let selectedHandler: (_ ratio: CGSize) -> Void
    let closeHandler: () -> Void
    
    let collectionView: UICollectionView
    
    let verBtn = UIButton(type: .system)
    let horBtn = UIButton(type: .system)
    
    lazy var cellModels: [CellModel] = {
        let isPortrait = ratio.width < ratio.height
        
        let ratios = isPortrait ? Self.verRatios : (Self.verRatios.map { $0.exchange })
        var cellModels = ratios.map { CellModel(ratio: $0) }
        
        if imageSize.width != imageSize.height {
            cellModels.insert(CellModel(ratio: [1, 1]), at: 0)
        }
        
        let maxImgSide = max(imageSize.width, imageSize.height)
        let minImgSide = min(imageSize.width, imageSize.height)
        if isPortrait {
            cellModels.insert(CellModel(isOrigin: true, ratio: [minImgSide, maxImgSide]), at: 0)
        } else {
            cellModels.insert(CellModel(isOrigin: true, ratio: [maxImgSide, minImgSide]), at: 0)
        }
        
        return cellModels
    }()
    
    init(imageSize: CGSize, ratio: CGSize, selectedHandler: @escaping (_ ratio: CGSize) -> Void, closeHandler: @escaping () -> Void) {
        self.imageSize = imageSize
        self.ratio = ratio
        self.selectedHandler = selectedHandler
        self.closeHandler = closeHandler
        
        let verInset = (50.px - Cell.cellH) * 0.5
        let horInset = 16.px
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4.px
        layout.minimumInteritemSpacing = 4.px
        layout.sectionInset = UIEdgeInsets(top: verInset, left: horInset, bottom: verInset, right: horInset)
        self.collectionView = UICollectionView(frame: [0, 0, PortraitScreenWidth, 50.px], collectionViewLayout: layout)
        
        super.init(frame: [0, 0, PortraitScreenWidth, 50.px + NavBarH + DiffTabBarH])
        
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.register(Cell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        addSubview(collectionView)
        
        let y = 50.px
        let wh = NavBarH
        let space = 0.px
        let totalW = wh + 10.px + wh
        
        verBtn.tintColor = .white
        verBtn.addTarget(self, action: #selector(verAction), for: .touchUpInside)
        verBtn.frame = [(PortraitScreenWidth - totalW) * 0.5, y, NavBarH, NavBarH]
        addSubview(verBtn)
        
        horBtn.tintColor = .white
        horBtn.addTarget(self, action: #selector(horAction), for: .touchUpInside)
        horBtn.frame = [verBtn.frame.maxX + space, y, NavBarH, NavBarH]
        addSubview(horBtn)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        closeBtn.frame = [horInset, y, NavBarH, NavBarH]
        addSubview(closeBtn)
        
        updateBtnImage()
        reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateBtnImage() {
//        rectangle.portrait 垂直没选中
//        checkmark.rectangle.portrait.fill 垂直选中
//        rectangle 水平没选中
//        checkmark.rectangle.fill 水平选中
        let verImgName: String
        let horImgName: String
        if ratio.width == ratio.height {
            verImgName = "rectangle.portrait"
            horImgName = "rectangle"
        } else {
            if ratio.width > ratio.height {
                verImgName = "rectangle.portrait"
                horImgName = "checkmark.rectangle.fill"
            } else {
                verImgName = "checkmark.rectangle.portrait.fill"
                horImgName = "rectangle"
            }
        }
        verBtn.setImage(UIImage(systemName: verImgName), for: .normal)
        horBtn.setImage(UIImage(systemName: horImgName), for: .normal)
    }
    
    private func reloadData() {
        cellModels.forEach { $0.isSelected = $0.ratio == ratio }
        collectionView.reloadData()
    }
    
    private func exchangeRatio() {
        ratio = ratio.exchange
        cellModels.forEach {
            $0.ratio = $0.ratio.exchange
            $0.isSelected = $0.ratio == ratio
        }
        collectionView.reloadData()
    }
}

private extension CropRatioBar {
    @objc func verAction() {
        guard ratio.width > ratio.height else { return }
        exchangeRatio()
    }
    
    @objc func horAction() {
        guard ratio.width < ratio.height else { return }
        exchangeRatio()
    }
    
    @objc func closeAction() {
        closeHandler()
    }
}

extension CropRatioBar {
    class CellModel {
        let isOrigin: Bool
        
        var ratio: CGSize = .zero {
            didSet { updateTitle() }
        }
        
        private(set) var title: String = ""
        
        private(set) var cellW: CGFloat = 0
        
        var isSelected: Bool = false
        
        init(isOrigin: Bool = false, ratio: CGSize) {
            self.isOrigin = isOrigin
            self.ratio = ratio
            updateTitle()
            cellW = title.size(withAttributes: [.font: Cell.font]).width + 16.px
        }
        
        func updateTitle() {
            if isOrigin {
                title = "原始比例"
            } else if ratio.width == ratio.height {
                title = "正方形"
            } else {
                title = "\(Int(ratio.width)):\(Int(ratio.height))"
            }
        }
    }
    
    class Cell: UICollectionViewCell {
        static let cellH: CGFloat = 22.px
        static let font: UIFont = .systemFont(ofSize: 12.px)
        
        let titleLabel = UILabel()
        
        var isSel: Bool = false {
            didSet {
                guard isSel != oldValue else { return }
                titleLabel.textColor = UIColor(white: 1, alpha: isSel ? 1 : 0.5)
                contentView.backgroundColor = UIColor(white: 1, alpha: isSel ? 0.3 : 0)
            }
        }
        
        var cellModel: CellModel? = nil {
            didSet {
                guard let cellModel = cellModel else { return }
                isSel = cellModel.isSelected
                titleLabel.text = cellModel.title
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.layer.cornerRadius = Self.cellH * 0.5
            contentView.layer.masksToBounds = true
            contentView.backgroundColor = UIColor(white: 1, alpha: 0)
            
            titleLabel.font = Self.font
            titleLabel.textColor = UIColor(white: 1, alpha: 0.5)
            titleLabel.textAlignment = .center
            contentView.addSubview(titleLabel)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            titleLabel.frame = contentView.bounds
        }
    }
}

extension CropRatioBar: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cellModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
        cell.cellModel = cellModels[indexPath.item]
        return cell
    }
}

extension CropRatioBar: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellModel = cellModels[indexPath.item]
        return CGSize(width: cellModel.cellW, height: Cell.cellH)
    }
}

extension CropRatioBar: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        ratio = cellModels[indexPath.item].ratio
        reloadData()
    }
}
