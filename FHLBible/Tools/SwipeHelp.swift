//
//  SwipeHelp.swift
//  FHLBible
//
//  Created by littlesnow on 2021/12/16.
//

import Foundation
import UIKit
import FHLCommon

/// 手勢，向左滑 向右滑
/// lazy var _swipeHelp = SwipeHelp(view: self.view, viewController: self)
class SwipeHelp: NSObject {
    init(view: UIView, viewController: UIViewController? = nil){
        self.view = view
        self.viewController = viewController
    }
    var onSwipe$: IjnEvent<Any,UISwipeGestureRecognizer> = IjnEvent()

    weak var viewController: UIViewController?
    private var _hasRightSwipe = false
    private var view: UIView!
    private weak var _savedPopDelegate: UIGestureRecognizerDelegate?
    private weak var _savedContentPopDelegate: UIGestureRecognizerDelegate?

    func addSwipe(dir: UISwipeGestureRecognizer.Direction, numberOfTouches: Int = 1){
        if dir == .right { _hasRightSwipe = true }
        let r1 = UISwipeGestureRecognizer(target: self, action: #selector(doSwipe(sender:)))
        r1.direction = dir
        r1.numberOfTouchesRequired = numberOfTouches
        view.addGestureRecognizer(r1)

        _gestures.append(r1)
    }
    /// 在 VC 的 viewWillAppear 呼叫，停用 iOS 系統的向右滑返回手勢
    func onViewWillAppear(){
        guard _hasRightSwipe else { return }
        guard let nav = viewController?.navigationController else { return }
        // 停用舊的「從左緣」返回手勢
        if let pop = nav.interactivePopGestureRecognizer {
            _savedPopDelegate = pop.delegate
            pop.delegate = self
        }
        // iOS 26+ 新增的「從任意位置」返回手勢
        if #available(iOS 26, *) {
            if let contentPop = nav.interactiveContentPopGestureRecognizer {
                _savedContentPopDelegate = contentPop.delegate
                contentPop.delegate = self
            }
        }
    }
    /// 在 VC 的 viewWillDisappear 呼叫，恢復 iOS 系統的向右滑返回手勢
    func onViewWillDisappear(){
        guard let nav = viewController?.navigationController else { return }
        nav.interactivePopGestureRecognizer?.delegate = _savedPopDelegate
        _savedPopDelegate = nil
        if #available(iOS 26, *) {
            nav.interactiveContentPopGestureRecognizer?.delegate = _savedContentPopDelegate
            _savedContentPopDelegate = nil
        }
    }
    @objc private func doSwipe(sender: UISwipeGestureRecognizer){
        onSwipe$.trigger(self, sender)
     }
    private var _gestures: [UISwipeGestureRecognizer] = []
}

extension SwipeHelp: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
