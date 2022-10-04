//
//  SwipeHelp.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/16.
//

import Foundation
import UIKit

/// 手勢，向左滑 向右滑
/// lazy var _swipeHelp = SwipeHelp(view: self.view)
class SwipeHelp {
    init(view: UIView){
        self.view = view
    }
    var onSwipe$: IjnEvent<Any,UISwipeGestureRecognizer> = IjnEvent()
    
    private var view: UIView!
    func addSwipe(dir: UISwipeGestureRecognizer.Direction, numberOfTouches: Int = 1){
        let r1 = UISwipeGestureRecognizer(target: self, action: #selector(doSwipe(sender:)))
        r1.direction = dir
        r1.numberOfTouchesRequired = numberOfTouches
        view.addGestureRecognizer(r1)
        
        _gestures.append(r1)
    }
    @objc private func doSwipe(sender: UISwipeGestureRecognizer){
        onSwipe$.trigger(self, sender)
     }
    private var _gestures: [UISwipeGestureRecognizer] = []
}
