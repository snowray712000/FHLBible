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

    class DReloadDataViaScApi : DReloadData {
        private var reScApi: DApiSc
        init(_ result: DApiSc){
            self.reScApi = result
        }
        override var addrNext: DAddress? {
            get {
                if reScApi.next == nil {
                    return nil
                }
                return reScApi.next!.toAddress()
            }
        }
        override var addrPrev: DAddress? {
            get {
                if reScApi.prev == nil {
                    return nil
                }
                return reScApi.prev!.toAddress()
            }
        }
        override var com_text: String? {
            get {
                // self.apiResult!.record.first!.com_text ?? ""
                if reScApi.record.count == 0 {
                    return nil
                }
                return reScApi.record.first!.com_text
            }
        }
    }
    

    class ReloadDataViaScApi : IReloadData {
        override init(){
            tpSc = .comment
            super.init()
        }
        override var apiFinished$: IjnEventOnce<[DText], VCComment.DReloadData> {
            get { return event$}
        }
        
        override func reloadAsync(_ addr: DAddress) {
            api.apiFinished$.addCallback { sender, pData in
                if sender != nil {
                    self.event$.triggerAndCleanCallback(sender, nil)
                } else {
                    self.event$.triggerAndCleanCallback(nil, DReloadDataViaScApi(pData!))
                }
            }
            api.main(addr, self.tpSc)
        }
        /// 開發完 comment, 發現 tsk 只有這個不一樣, 所以重構抽出
        var tpSc: FhlScCore.TpBook
        private var event$: IjnEventOnce<[DText], VCComment.DReloadData> = IjnEventOnce()
        private var api = FhlScCore()
    }
    
}
