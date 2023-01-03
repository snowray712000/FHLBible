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


extension VCParsing {
    /// 參考 comment 的作法
    class DReloadData : NSObject{
        func isSuccess()->Bool { return true}
        var addrNext: DAddress? {get {return nil}}
        var addrPrev: DAddress? {get {return nil}}
        var data: ConvertorQp2VCParsingData.DData? {get {return nil}}
    }
    /// 參考 comment 的作法
    class DReloadData2 : DReloadData{
        override func isSuccess() -> Bool { return _isSuccess ?? true }
        override var addrNext: DAddress? {get {return _next} set { _next = newValue} }
        override var addrPrev: DAddress? {get {return _prev} set { _prev = newValue} }
        override var data: ConvertorQp2VCParsingData.DData? {get {return _data } set { _data = newValue } }
        private var _next: DAddress?
        private var _prev: DAddress?
        private var _data: ConvertorQp2VCParsingData.DData?
        private var _isSuccess: Bool?
    }
    /// 參考 comment 的作法
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
