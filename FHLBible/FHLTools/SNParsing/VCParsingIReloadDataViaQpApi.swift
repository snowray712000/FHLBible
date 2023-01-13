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
    /// 參考 Comment 的作法
    class DReloadDataViaQpApi : DReloadData {
        private var reApi: DApiQp
        init(_ result: DApiQp){
            self.reApi = result
        }
        func cvt(_ pn: DApiQp.PrevNext)->DAddress {
            let idBook = BibleBookNameToId().main1based(.Matt, pn.engs! )
            return DAddress(book: idBook, chap: pn.chap!, verse: pn.sec!, ver: nil)
        }
        override var addrNext: DAddress? {
            get {
                if reApi.next == nil {
                    return nil
                }
                return cvt(reApi.next!)
            }
        }
        override var addrPrev: DAddress? {
            get {
                if reApi.prev == nil {
                    return nil
                }
                return cvt(reApi.prev!)
            }
        }
        override var data: ConvertorQp2VCParsingData.DData? {
            get {
                if reApi.record.count == 0 {
                    return nil
                }
                return ConvertorQp2VCParsingData.DDataViaQpApi(reApi)
            }
        }
    }
    

    class ReloadDataViaScApi : IReloadData {
        override init(){
            super.init()
        }
        override var apiFinished$: IjnEventOnce<[DText], VCParsing.DReloadData> {
            get { return event$}
        }
        
        override func reloadAsync(_ addr: DAddress) {
            fhlQp(toParamString(addr)){ data in
                if data.isSuccess() {
                    self.apiFinished$.triggerAndCleanCallback(nil, DReloadDataViaQpApi(data))
                } else {
                    self.apiFinished$.triggerAndCleanCallback([DText("qp api failure.")], nil)
                }
            }
        }
        private var event$: IjnEventOnce<[DText], VCParsing.DReloadData> = IjnEventOnce()
        private var api = FhlScCore()
        
        private func toParamString(_ addr: DAddress)->String{
            let r1 = BibleBookNames.getBookName(addr.book, .Matt)
            return "engs=\(r1)&chap=\(addr.chap)&sec=\(addr.verse)&\(ManagerLangSet.s.curQueryParamGb)"
        }
    }
    class ReloadDataAutoUseOfflineOrScApi : IReloadData {
        
        override init(){
            super.init()
            if self.isExistOffline() {
                core = ReloadDataViaOfflineDatabase()
            } else {
                core = ReloadDataViaScApi()
            }
        }
        override var apiFinished$: IjnEventOnce<[DText],DReloadData> { get { return core!.apiFinished$ } }
        override func reloadAsync(_ addr: DAddress) {
            core!.reloadAsync(addr)
        }
        var core: IReloadData?
        private func isExistOffline() -> Bool {
            let na = ManagerLangSet.s.curIsGb ? "parsing_gb.db" : "parsing.db"
            let r1 = FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/\(na)")
            return FileManager.default.fileExists(atPath: r1.path)
        }
        
    }
}
