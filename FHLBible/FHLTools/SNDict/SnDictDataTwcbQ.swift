import Foundation
import FHLCommon


class SnDictDataTwcbQ {
    /// 第1個參數，若有錯誤訊息時，放在那
    var onApiFinished$: IjnEventOnce<[DText],DApiSbdBase> = IjnEventOnce()
    
    func main(_ dtext: DText){
        assert ( dtext.sn != nil && dtext.tp != nil )
        
        let N = dtext.tp == "H" ? 1:0
        let r1 = "k=\(dtext.sn!)&\(ManagerLangSet.s.curQueryParamGb)&N=\(N)"
        
        if N == 1 {
            fhlStwcbhdic(r1) { data in
                self.step2(data, r1)
            }
        } else {
            fhlSbdag(r1) { data in
                self.step2(data, r1)
            }
        }
    }
    private func triggerError(_ msg:String){
        self.onApiFinished$.triggerAndCleanCallback([DText(msg)], nil)
    }
    private func step2(_ data: DApiSbdBase, _ r1: String) {
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
