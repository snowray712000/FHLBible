//
//  ScrollViewCaptureImage.swift
//  FHLBible
//
//  Created by littlesnow on 2023/12/8.
//

import Foundation
import UIKit
class EventForScrollView : NSObject, UIScrollViewDelegate{
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("scrollViewDidEndScrollingAnimation")
        ev_scrollViewDidEndScrollingAnimation.triggerAndCleanCallback()
    }
    var ev_scrollViewDidEndScrollingAnimation = IjnEventOnceAny()
    static let shared = EventForScrollView()
    
    
}
extension UIScrollView {
    /**
     為了截圖，當時寫了這個，卷動並取得所有影像。
     - 原本用在 UITextView
     */
    func capture(fnDoImageCompleted: @escaping (_ image: UIImage?)->Void ) {
        let oldDelegate = delegate
        let savedContentOffset = contentOffset
        
        delegate = EventForScrollView.shared

        func renderToImage()->UIImage?{
            let dy = floor( frame.height )
            var cnt = Int( ceil( contentSize.height / frame.height ) )
            // Begin End 包起來，是畫圖的部分 .render 真正畫的地方
            UIGraphicsBeginImageContextWithOptions(contentSize, false, UIScreen.main.scale)
            guard let currentContext = UIGraphicsGetCurrentContext() else {
                return nil
            }
            for idx in 0..<cnt{
                cnt = Int( ceil( contentSize.height / frame.height ) ) // contentSize 會持續變化，所以才加這行
                contentOffset = CGPoint(x:0, y: CGFloat(idx) * dy )
                layer.render(in: currentContext)
            }
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        
        // 避免程式 Bug, 一直沒觸發上一次的, callback 一直累積，因此透過呼叫此清空它
        EventForScrollView.shared.ev_scrollViewDidEndScrollingAnimation.triggerAndCleanCallback()
        EventForScrollView.shared.ev_scrollViewDidEndScrollingAnimation.addCallback {[weak self] sender, pData in
            let image = renderToImage()
            self?.contentOffset = savedContentOffset
            self?.delegate = oldDelegate
            fnDoImageCompleted(image)
        }
        
        // 坑: 第一次 scroll 到 contentSize.height - 1 會只到一半
        // 坑: 第二次 scroll 到 sizeThatFits-1 就不會生效。
        // 坑: 太少資料，scroll 不觸發。
        // 坑: 有人滾到最下面，才按，就不觸發了。
        // 兩種都呼叫，測試正確。而且 ScrollingAnimation 也只有一次
        //  首先，從頭卷到尾一次，讓所有都畫過一次，不然中間會有空白，要從頭開始卷。但通常上面都已經看過了，所以從目前向底部卷動即可
        if frame.height < contentSize.height {
            contentOffset.y = 0
            let sz = sizeThatFits(contentSize) // 直接用 contentSize 會有問題，所以用 sizeThatFits
            scrollRectToVisible(CGRect(x: 0, y: sz.height - 1, width: 1, height: 1), animated: true)
            scrollRectToVisible(CGRect(x: 0, y: contentSize.height - 1, width: 1, height: 1), animated: true)
        } else {
            EventForScrollView.shared.ev_scrollViewDidEndScrollingAnimation.triggerAndCleanCallback()
        }
    }
}
