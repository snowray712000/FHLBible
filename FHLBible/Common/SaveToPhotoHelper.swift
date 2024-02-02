//
//  SaveToPhotoHelper.swift
//  FHLBible
//
//  Created by littlesnow on 2023/12/13.
//

import Foundation
import UIKit

///

/**
 因為 UIImageWriteToSavedPhotosAlbum 的 callback 必需使用 #selector 不能使用閉包。所以才有這個 class
 - 原本是 LongPress 相關用到
 - 因為 Read 也要存圖，所以也重構出來
 */
class SaveToPhotoHelper: NSObject{
    /// 提供給預設的 callback messagebox 用的. 其實原本不用
    weak var vc: UIViewController!
    var evCompleted = IjnEventOnce<Any,(isOk:Bool,er: String?)>()
    func main(vc: UIViewController,img: UIImage){
        // 儲存影像
        self.vc = vc
        UIImageWriteToSavedPhotosAlbum(img, self, #selector(self._image_saved(_:didFinishSavingWithError: contextInfo:)), nil)
    }
    /**
     為了 _add_generate_image_save_to_photo 而存在。
     - UIImageWriteToSavedPhotosAlbum 的 callback ， 必需使用 #selector 不能使用閉包。
     */
    @objc func _image_saved(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            if evCompleted.isEmptyCallback {
                let msg2 = NSLocalizedString("儲存影像失敗", comment: "")
                MessageBox.ok(vc: self.vc, msg: msg2 + ": \(error.localizedDescription)")
            } else {
                evCompleted.triggerAndCleanCallback(vc, (isOk: false, er: error.localizedDescription))
            }
        } else {
            if evCompleted.isEmptyCallback {
                MessageBox.ok(vc: self.vc, msg: "儲存影像成功")
            } else {
                evCompleted.triggerAndCleanCallback(vc, (isOk: true, er: nil))
            }
        }
    }
}
/**
 一個會被重複呼叫的流程
  
     viewOfImage.capture { image in
         guard let image = image else {
             MessageBox.ok(vc: vc, msg: "產生影像失敗")
             return
         }
         
         // 儲存影像
         let saver = SaveToPhotoHelper()
         saver.main(vc: vc, img: image)
     }
 */
func generate_and_save_and_msgbox_image_of_scrollview(viewOfImage: UIScrollView,vc: UIViewController){
    // 產生影像，儲存影像。
    viewOfImage.capture { image in
        guard let image = image else {
            MessageBox.ok(vc: vc, msg: "產生影像失敗")
            return
        }
        
        // 儲存影像
        let saver = SaveToPhotoHelper()
        saver.main(vc: vc, img: image)
    }
}
