import Foundation
import FMDB
class SnDictDataCbolQAuto {
    /// 第1個參數，若有錯誤訊息時，放在那
    var onApiFinished$: IjnEventOnce<[DText],DApiSd> = IjnEventOnce()
    fileprivate func triggerError(_ msg:String){
        self.onApiFinished$.triggerAndCleanCallback([DText(msg)], nil)
    }
    func mainAsync(_ dtext:DText){
        let r1: SnDictDataCbolQAuto = SQLCBOLDict.isExist() ? SnDictDataCbolQOffline() : SnDictDataCbolQ()
        r1.onApiFinished$.addCallback { sender, pData in
            self.onApiFinished$.triggerAndCleanCallback(sender, pData)
        }
        r1.mainAsync(dtext)
    }
}
/// 查詢資料
class SnDictDataCbolQ : SnDictDataCbolQAuto {
    /// 第1個參數，若有錯誤訊息時，放在那
    override func mainAsync(_ dtext:DText){
        assert ( dtext.sn != nil && dtext.tp != nil )
        
        let N = dtext.tp == "H" ? 1 : 0
        
        let r1 =  "k=\(dtext.sn!)&\(ManagerLangSet.s.curQueryParamGb)&N=\(N)"
        
        fhlSd(r1) { data in
            if data.isSuccess() == false {
                self.triggerError("api失敗, 參數為 \(r1).")
            } else {
                if data.record.count == 0 {
                    self.triggerError("api成功, 但資料是空的, 參數為 \(r1)")
                } else {
                    self.onApiFinished$.triggerAndCleanCallback(nil, data)
                }
            }
        }
    }
    
    
}
class SnDictDataCbolQOffline : SnDictDataCbolQAuto {
    override func mainAsync(_ dtext:DText){
        assert ( dtext.sn != nil && dtext.tp != nil )
        let isOld = dtext.tp == "H" ? 1 : 0
        let snTool = SnSplitSuffix(dtext.sn!)
        let cmd = "select * from sndict2 where sn=\(snTool.sn!) and isOld=\(isOld) and snSuffix='\(snTool.snSuffix)';"
        
        let objSQL = SQLCBOLDict()
        let re = objSQL.doSelect(stringOfSQLite: cmd, args: nil) { (a1:FMResultSet) in
            if ( a1.next() ){
                let txt = a1.string(forColumn: "txt")
                let orig = a1.string(forColumn: "orig")
                let sn = a1.int(forColumn: "sn")
                let suf = a1.string(forColumn: "snSuffix")
                let isOld = a1.int(forColumn: "isOld")
                
                let re = DApiSd()
                re.status = "success"
                re.record = []
                
                let r1 = DApiSdRecord()
                r1.sn = "\(sn)\(suf!)"
                r1.orig = orig
                r1.dic_text = txt
                r1.edic_text = ""
                r1.dic_type = Int( isOld)
                re.record.append(r1)
                
                self.onApiFinished$.triggerAndCleanCallback(nil, re)
            } else {
                self.triggerError("select 成功, 但資料是空的. 查詢的字: \(dtext.w!)")
            }
        }
        if re == false {
            self.triggerError("SQL失敗, 錯誤資訊為 \(objSQL.lastErrorMessage!).")
        }
    }
}
