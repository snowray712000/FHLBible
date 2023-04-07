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
    func gEasyGetViewCtrlFromXibCore<T>(_ idOfStoryboard:String)->T where T:UIViewController { self.storyboard!.instantiateViewController(withIdentifier: idOfStoryboard) as! T }
    func gVCRead()->VCRead {
        self.gEasyGetViewCtrlFromXibCore("VCRead")
    }
    func gVCTsk()->VCTsk { self.gEasyGetViewCtrlFromXibCore("VCTsk") }
    func gVCComment()->VCComment { self.gEasyGetViewCtrlFromXibCore("VCComment")}
    func gVCVersionsPicker()->VCVersionsPicker { self.gEasyGetViewCtrlFromXibCore("VCVersionsPicker")}
    /// 使用 initBeforePushVC、onClick$
    func gVCBookChapPicker()->VCBookChapPicker { self.gEasyGetViewCtrlFromXibCore("VCBookChapPicker")}
    func gVCParsing() -> VCParsing {gEasyGetViewCtrlFromXibCore("VCParsing")}
    func gVCReadHistory() -> VCReadHistory { self.gEasyGetViewCtrlFromXibCore("VCReadHistory")}
    func gVCSnDict() -> VCSnDict { self.gEasyGetViewCtrlFromXibCore("VCSnDict")}
    func gVCVersionsCompareInOneVerse() -> VCVersionsCompareInOneVerse { self.gEasyGetViewCtrlFromXibCore("VCVersionsCompareInOneVerse")}
    /// 按下某個 SN 的字的時候，跳出的選單
    func gVCSnActionPicker() -> VCSnActionPicker { self.gEasyGetViewCtrlFromXibCore("VCSnActionPicker")}
    /// 關鍵字查詢，輸入界面
    func gVCSearching() -> VCSearching { self.gEasyGetViewCtrlFromXibCore("VCSearching")}
    /// 關鍵字查詢結果，彙編都會用到
    func gVCSearchResult() -> VCSearchResult { self.gEasyGetViewCtrlFromXibCore("VCSearchResult")}
    /// 按下 經文顯示 左側 時，會用到的 ctrl
    func gVCVerseActionPicker() -> VCVerseActionPicker { self.gEasyGetViewCtrlFromXibCore("VCVerseActionPicker")}
    /// Footer (閱讀過程，某些版本 cnet csb，會有【23】這種注腳。
    func gVCFooter() -> VCFooter { self.gEasyGetViewCtrlFromXibCore("VCFooter")}
    func gVCAudioBible() -> VCAudioBible { self.gEasyGetViewCtrlFromXibCore("VCAudioBible")}
}
