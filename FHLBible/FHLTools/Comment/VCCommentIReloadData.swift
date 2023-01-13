//
//  VCComment.swift
//  FHLBible
//
//  Created by littlesnow on 2021/11/10.
//

import Foundation
import UIKit
import IJNSwift
import FMDB


extension VCComment {
    class DReloadData : NSObject{
        var addrNext: DAddress? {get {return nil}}
        var addrPrev: DAddress? {get {return nil}}
        var com_text: String? {get{return nil}}
    }
    class DReloadData2 : DReloadData{
        override var addrNext: DAddress? {get {return _next} set { _next = newValue} }
        override var addrPrev: DAddress? {get {return _prev} set { _prev = newValue} }
        override var com_text: String? {get {return _txt} set { _txt = newValue } }
        private var _next: DAddress?
        private var _prev: DAddress?
        private var _txt: String?
    }
    
    class IReloadData : NSObject{
        /// DText[] sender 若不是 nil, 表示是錯誤訊息
        /// sender = nil 時, pData 就一定不是 nil
        var apiFinished$: IjnEventOnce<[DText],DReloadData> { get { return IjnEventOnce(); } }

        func reloadAsync(_ addr:DAddress){
            DispatchQueue.global().async {
                self.apiFinished$.triggerAndCleanCallback([DText("過載reloadAsync吧")], nil)
            }
        }
    }
}
