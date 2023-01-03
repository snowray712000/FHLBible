//
//  messageBox.swift
//  FHLBible
//
//  Created by littlesnow on 2022/11/2.
//

import Foundation
import UIKit
class MessageBox : NSObject {
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
}
