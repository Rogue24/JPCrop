//
//  NavigationController.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2022/9/10.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    override var childForStatusBarHidden: UIViewController? { topViewController }
    override var childForStatusBarStyle: UIViewController? { topViewController }
}
