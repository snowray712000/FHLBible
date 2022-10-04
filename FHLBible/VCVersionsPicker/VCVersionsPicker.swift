//
//  VCVersionsPicker.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/4.
//

import UIKit

class VCVersionsPicker : UIViewController {
    /// [unv csv] ...
    /// isUpdateCurVersWhenOkay 是因為 compare 的版本，不要隨著變
    func setInitData(_ selections:[String],isUpdateCurVersWhenOkay: Bool = true ) {
        self._selections = selections
        self._isUpdateCurVersWhenOkay = isUpdateCurVersWhenOkay
        var r1 = ManagerBibleVersions.s.recent
        r1.removeAll(where: {selections.contains($0)})
        self._recentlys = r1
        self._sets = ManagerBibleVersions.s.sets
    }
    override func viewDidLoad() {
        super.viewDidLoad()
     
        let isOnSub = ManagerBibleVersions.s.isOnSub
        let tpSub1 = ManagerBibleVersions.s.optSub
        viewMain.setInitData(_selections, _recentlys, _sets, isOnSub, tpSub1)
    }
    /// 希望「Back」，也同時是確認，好像是按下 okay 一樣
    override func viewDidDisappear(_ animated: Bool) {
        if self._isClickedCancel {
            return // 不作什麼
        }
        
        if self._isClickedOkay == false {
            self.clickOkay() // 去 click okay
        }
    }
    
    fileprivate var _selections: [String] = []
    fileprivate var _recentlys: [String] = []
    fileprivate var _sets: [[String]] = []
    fileprivate var _isUpdateCurVersWhenOkay: Bool!
    
    var onClickCancel$: IjnEventOnce<Any,Any> = IjnEventOnce()
    var onClickOkay$: IjnEventOnce<Any,[String]> = IjnEventOnce()
    @IBOutlet var viewMain: ViewVersionsPicker!
    @IBAction func clickCancel(){
        self._isClickedCancel = true
        
        self.navigationController?.popViewController(animated: false)
        onClickCancel$.triggerAndCleanCallback(nil, nil)
    }
    /// 希望「Back」，也同時是確認，好像是按下 okay 一樣
    fileprivate var _isClickedCancel = false
    /// 希望「Back」，也同時是確認，好像是按下 okay 一樣
    fileprivate var _isClickedOkay = false
    @IBAction func clickOkay(){
        self._isClickedOkay = true
        
        self.navigationController?.popViewController(animated: false)
        let r1 = viewMain.datasSelection
        let r2 = viewMain.datasRecently
        let r3 = viewMain.datasSet
        let r4 = viewMain.isOnOff // 次分類
        let r5 = viewMain.optSub1
        
        /// verse compare 就不要更新 cur, 它外部會自己更新
        if _isUpdateCurVersWhenOkay {
            ManagerBibleVersions.s.updateCur(r1)
        }
        ManagerBibleVersions.s.updateRecent(r2)
        ManagerBibleVersions.s.updateSets(r3)
        ManagerBibleVersions.s.updateOnSub(r4)
        ManagerBibleVersions.s.updateOptSub(r5)
        onClickOkay$.triggerAndCleanCallback(nil, r1)
    }
}

