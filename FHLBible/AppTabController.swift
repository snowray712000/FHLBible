//
//  AppTabController.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import Foundation
import UIKit

class AppTabController : UITabBarController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _ = AutoLoadDUiabv.s // lazy load
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
