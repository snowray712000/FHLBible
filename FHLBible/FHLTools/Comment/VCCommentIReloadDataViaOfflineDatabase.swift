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
    class ReloadDataViaOfflineDatabase : IReloadData {
        override init() {
            tagInDatabase = 3 // 註釋
            super.init()
            
        }
        override var apiFinished$: IjnEventOnce<[DText], DReloadData> { get { return _apiFinished$ }}
        private var _apiFinished$:IjnEventOnce<[DText], DReloadData> = IjnEventOnce()
        override func reloadAsync(_ addr: DAddress) {
            DBComment().queryCommentAsync(addr, tagInDatabase) {( a1:DBComment.DResultComment, a2:Bool) in
                
                if a2 {
                    self.apiFinished$.triggerAndCleanCallback(nil, self.cvtDBResultToReloadData(a1))
                } else {
                    self.apiFinished$.triggerAndCleanCallback([DText(a1.txt)], nil)
                }
            }
        }
        /// 開發串珠，發現幾乎一樣，所以重構此。 3 就是註釋， 4是串珠
        var tagInDatabase:Int

        private func cvtDBResultToReloadData(_ a1:DBComment.DResultComment)->DReloadData2 {
            let re = DReloadData2()
            
            re.com_text = a1.txt
            
            // prev
            if a1.bchap == 0 {
                re.addrPrev = nil
            } else {
                let r2 = DAddress(a1.book, a1.bchap, a1.bsec)
                let r3 = r2.goPrevVerse()
                if r2.book != r3.book {
                    re.addrPrev = DAddress(a1.book, 0, 0)
                } else {
                    re.addrPrev = r3
                }
            }
            
            // next
            if a1.bchap == 0{
                re.addrNext = DAddress(a1.book, 1, 1)
            } else {
                let r2 = DAddress(a1.book, a1.echap, a1.esec)
                let r3 = r2.goNextVerse()
                if r2.book != r3.book {
                    re.addrNext = nil
                } else {
                    re.addrNext = r3
                }
            }
    
            return re
        }
        
        class DBComment : EasySQLiteBase {
            override var pathToDatabase: URL! {
                get {
                    let na = ManagerLangSet.s.curIsGb ? "comm_gb.db" : "comm.db"
                    return FileManager.default.getPathAtDocumentUserDomain(pathRelative: "/offline/\(na)")
                }
            }
            struct DResultComment {
                var book = -1
                var bchap = -1
                var bsec = -1
                var echap = -1
                var esec = -1
                var txt = ""
            }
            /// tag=3, 是註釋，tag=4是串珠。
            func queryCommentAsync(_ addr:DAddress,_ tag:Int,_ fn: @escaping (DResultComment,Bool) -> Void){
                let cmd = SQLSelectBibleCommentsGenerator().main(address: addr, tag: tag, cntLimit: 1)
                
                let isSuccess = self.doSelect(stringOfSQLite: cmd, args: nil) { (a1:FMResultSet) in

                    if a1.next() {
                        let book  = Int(a1.int(forColumn: "book"))
                        let bchap = Int(a1.int(forColumn: "bchap"))
                        let bsec  = Int(a1.int(forColumn: "bsec"))
                        let echap = Int(a1.int(forColumn: "echap"))
                        let esec  = Int(a1.int(forColumn: "esec"))
                        let txt   = a1.string(forColumn: "txt")
                        
                        let r1 = DResultComment(book: book, bchap: bchap, bsec: bsec, echap: echap, esec: esec, txt: txt!)
                        fn(r1,true)
                    } else {
                        var r1 = DResultComment()
                        r1.txt = "Count Of Result = 0, although query database successfully."
                        fn(r1,false)
                    }
                }
                
                if isSuccess == false {
                    var r1 = DResultComment()
                    r1.txt = self.lastErrorMessage
                    fn(r1,false)
                }
            }
        }
    }
}
