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
    /// 參考 Comment 寫的
    class ReloadDataViaOfflineDatabase : IReloadData {
        override init() {
            super.init()
            
        }
        override var apiFinished$: IjnEventOnce<[DText], DReloadData> { get { return _apiFinished$ }}
        private var _apiFinished$:IjnEventOnce<[DText], DReloadData> = IjnEventOnce()
        override func reloadAsync(_ addr: DAddress) {
            DBParsing().queryParsingAsync(addr) {( a1:DBParsing.DResultParsing, a2:Bool) in
                
                if a2 {
                    self.apiFinished$.triggerAndCleanCallback(nil, self.cvtDBResultToReloadData(a1,addr))
                } else {
                    self.apiFinished$.triggerAndCleanCallback([DText(a1.lastError!)], nil)
                }
            }
        }
        private func cvtDBResultToReloadData(_ a1:DBParsing.DResultParsing,_ addr:DAddress)->DReloadData2 {
            let re = DReloadData2()
            
            re.addrNext = addr.goNextVerse()
            re.addrPrev = addr.goPrevVerse()
            
            re.data = DData2(a1, addr)
    
            return re
        }
        /// 核心與資料庫互動的部分
        class DBParsing : EasySQLiteBase {
            override var pathToDatabase: URL! {
                get {
                    let na = ManagerLangSet.s.curIsGb ? "parsing_gb.db" : "parsing.db"
                    return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/\(na)")
                }
            }
            struct DResultParsing {
                var lastError:String?
                var record: [DApiQpRecord]?
            }
            func queryParsingAsync(_ addr:DAddress,_ fn: @escaping (DResultParsing,Bool) -> Void){
                let na = addr.book < 40 ? "lparsing2":"fhlwhparsing2"
                let cmd = "SELECT * FROM \(na) WHERE book=\(addr.book) AND chap=\(addr.chap) And sec=\(addr.verse) ORDER by wid;"
                
                let isSuccess = self.doSelect(stringOfSQLite: cmd, args: nil) { (a1:FMResultSet) in

                    var records: [DApiQpRecord] = []
                    while a1.next() {
                        let r1 = DApiQpRecord()
                        r1.id = Int(a1.int(forColumn: "id"))
                        r1.wid = Int(a1.int(forColumn: "wid"))
                        r1.word = a1.string(forColumn: "word")
                        r1.sn = a1.string(forColumn: "sn")
                        r1.pro = a1.string(forColumn: "pro")
                        r1.wform = a1.string(forColumn: "wform")
                        r1.orig = a1.string(forColumn: "orig")
                        r1.exp = a1.string(forColumn: "exp")
                        r1.remark = a1.string(forColumn: "remark")
                        
                        if r1.wid == 0 {
                            // 創1:2，offline database 中，它的 word 就是要前面會多空白字元，造成後面的結果錯誤
                            // 創1:6，word 會是 nil
                            r1.word = r1.word?.trimmingCharacters(in: CharacterSet.whitespaces)
                        }
                        
                        if r1.wid != 0 { // 離線資料 pro wform 會是 ngsm 之類的東西
                            let r2 = SNParsingDealProXForm().main(r1.pro,r1.wform)
                            r1.pro = r2.0
                            r1.wform = r2.1
                        }
                        
                        records.append(r1)
                    }
                    
                    // 這是有的沒有的保護
                    if records.count > 0 {
                        // 彼前3:20
                        let r1 = records.first
                        if r1!.word == nil || r1!.exp == nil {
                            r1!.word = "."
                            r1!.exp = "離線資料異線，請回報此章節.謝謝."
                        }
                    }
                    
                    var r1 = DResultParsing()
                    r1.record = records
                    if records.count == 0 {
                        r1.lastError = "database query succeess, but data count is 0. address:\(addr.toString(.太))"
                        fn(r1, false)
                    } else {
                        fn(r1, true)
                    }
                }
                
                if isSuccess == false {
                    var r1 = DResultParsing()
                    r1.lastError = self.lastErrorMessage
                    fn(r1,false)
                }
            }
        }
        /// 為了符合 cvtDBResultToReloadData 的 return 型態
        class DData2 : ConvertorQp2VCParsingData.DData {
            init(_ data: DBParsing.DResultParsing,_ addr:DAddress){
                self._data = data
                self._addr = addr
            }
            var _data: DBParsing.DResultParsing
            var _addr: DAddress
            override func isOldTestment() -> Bool {
                return _addr.book < 40
            }
            override var record: [DApiQpRecord]! { get {
                if _data.lastError != nil {
                    return []
                }
                
                return _data.record!
            } }
        }
        
    }
}
