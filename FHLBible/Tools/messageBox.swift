//
//  messageBox.swift
//  FHLBible
//
//  Created by littlesnow on 2022/11/2.
//

import Foundation
import UIKit
class MessageBox : NSObject {
    /**
     具有「刪除」「取消」按鈕的對話方塊
     */
    static func presentDeletionAlert(_ vc:UIViewController,_ message:String, fn:@escaping (UIAlertAction)->Void) {
        // 創造一個 UIAlertController 的實例。
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        // 加入刪除的動作。
        let deleteAction = UIAlertAction(title: "刪除", style: .destructive, handler: fn)
        
        alertController.addAction(deleteAction)

        // 加入取消的動作。
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alertController.addAction(cancelAction)

        // 呈現 alertController。
        vc.present(alertController, animated: true)
    }
    /**
     具有「確定」按鈕。通常作為 help 使用
     - 可傳入 function callback。
     - 裡面已經作 NSLocalizedString 轉換，所以使用者不用轉換
     */
    static func ok(vc: UIViewController,msg: String,title: String? = nil,fn: ((UIAlertAction)->Void)? = nil){
        let title = title ?? "確定"
        
        let title2 = NSLocalizedString(title, comment: "")
        let msg2 = NSLocalizedString(msg, comment: "")
        let confirm = NSLocalizedString("確定", comment: "")
        
        let alert = UIAlertController(title: title2, message: msg2, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirm, style: .default, handler: fn))
        vc.present(alert, animated: true, completion: nil)
    }
}
