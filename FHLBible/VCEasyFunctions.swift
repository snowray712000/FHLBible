//
//  VCEasyFunctions.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/28.
//

import Foundation
import UIKit
/// 因為 gVCVerseActionPicker gVCSearchResult 都會用到 重構
func easyGetViewCtrlFromXibCore<T>(_ idOfStoryboard:String ,_ ctrl:UIViewController) -> T where T: UIViewController {
    return ctrl.storyboard!.instantiateViewController(withIdentifier: idOfStoryboard) as! T
}



extension UIViewController {
    /// 以 UIHostingController 在程式碼中建立的畫面，storyboard 是 nil，改由 navigationController 或 Main 取得
    func gEasyGetViewCtrlFromXibCore<T>(_ idOfStoryboard:String)->T where T:UIViewController {
        let sb = self.storyboard ?? self.navigationController?.storyboard ?? UIStoryboard(name: "Main", bundle: nil)
        return sb.instantiateViewController(withIdentifier: idOfStoryboard) as! T
    }
    /// 閱讀已是 SwiftUI (`UIHostingController`)，不經由 storyboard
    func gVCRead()->VCRead {
        VCRead()
    }
    func gVCVersionsPicker()->VCVersionsPicker { self.gEasyGetViewCtrlFromXibCore("VCVersionsPicker")}
    /// 使用 initBeforePushVC、onClick$
    func gVCParsing() -> VCParsing {gEasyGetViewCtrlFromXibCore("VCParsing")}
    /// 按下某個 SN 的字的時候，跳出的選單
    func gVCSnActionPicker() -> VCSnActionPicker { self.gEasyGetViewCtrlFromXibCore("VCSnActionPicker")}
    /// 按下 經文顯示 左側 時，會用到的 ctrl
    func gVCVerseActionPicker() -> VCVerseActionPicker { self.gEasyGetViewCtrlFromXibCore("VCVerseActionPicker")}
    func gVCWhenLongPress() -> VCWhenLongPress { self.gEasyGetViewCtrlFromXibCore("VCWhenLongPress")}
}
