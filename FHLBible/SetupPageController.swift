//
//  SetupPageController.swift
//  FHLBible
//
//  Created by snowray712000@gmail.com on 2021/4/12.
//

import Foundation
import UIKit

class SetupPageController : UIPageViewController, UIPageViewControllerDataSource {
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource =  self
        
        if viewControllers?.count == 0 {
            setViewControllers( [DownloadManagerView(style: .grouped)], direction: .forward, animated: false, completion: nil)
        }
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }
}
