//
//  ImagePageViewController.swift
//  FHLBible
//
//  Created by littlesnow on 2025/2/8.
//
import Foundation
import UIKit
import ZIPFoundation
import zlib
import FHLCommon

class ImagePageViewController: UIPageViewController, UIPageViewControllerDataSource {
    // This property should be overridden by subclasses to provide their own image names
    // 儲存圖片檔名的陣列
    // 圖片是拉到 Assets 裡面
    var imageNames: [String] {
        return []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        
        if let firstVC = viewControllerForPage(0) {
            setViewControllers([firstVC], direction: .forward, animated: true)
        }
    }
    
    // 產生對應頁面的 ViewController
    func viewControllerForPage(_ index: Int) -> UIViewController? {
        
        guard index >= 0, index < imageNames.count else { return nil }
        
        let vc = UIViewController()
        
        // 創建圖片視圖
        let imageView = UIImageView(image: UIImage(named: imageNames[index]))
        // imageView.contentMode = .scaleAspectFit  // 確保圖片比例正確
        imageView.contentMode = .scaleToFill
        imageView.translatesAutoresizingMaskIntoConstraints = false

        vc.view.addSubview(imageView)

        // 設定圖片視圖貼邊的 Auto Layout
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor), // 左貼邊
            imageView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor), // 右貼邊
            imageView.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor), // 上貼邊
            imageView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor) // 下貼邊
        ])
        
        vc.view.tag = index
        return vc
    }
    
    // 前一頁
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        return viewControllerForPage(currentIndex - 1)
    }
    
    // 下一頁
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        return viewControllerForPage(currentIndex + 1)
    }
}
