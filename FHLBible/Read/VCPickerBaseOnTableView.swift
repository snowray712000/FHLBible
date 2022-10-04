//
//  ViewPickerBase.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit

/// 原本先作 SnAction Picker
/// 後來作 Verse Action 時，發現幾乎一樣，就重構成這個
/// 要記得將 cell 的 id 設為 'cell'
class VCPickerBaseOnTableView<T> : VCOptionListViaTableViewControllerBase {
    var onPicker$: IjnEventOnce<UIView,T> = IjnEventOnce()
    func getSelected(_ i: Int) -> T? {return nil}
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        _onClickRow$.addCallback { sender, pData in
            let re = self.getSelected(pData!)
            
            // 兩種都有，就可以兩種都用，若不是 present ，呼叫 dismiss 也沒有關係
            self.dismiss(animated: false, completion: nil)
            self.navigationController?.popViewController(animated: false)
            
            self.onPicker$.triggerAndCleanCallback(self.view, re)
        }
    }
    
    override var _ovIsLastRedForCancel: Bool { false }
}
