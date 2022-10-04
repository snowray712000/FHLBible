import Foundation

/// 查詢資料
class SnDictDataCbolQ {
    /// 第1個參數，若有錯誤訊息時，放在那
    var onApiFinished$: IjnEventOnce<[DText],DApiSd> = IjnEventOnce()
    func main(_ dtext:DText){
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
    
    private func triggerError(_ msg:String){
        self.onApiFinished$.triggerAndCleanCallback([DText(msg)], nil)
    }
}
