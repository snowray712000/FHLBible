import Foundation

/// 開發此，是為了 Page 取得資料
/// 規畫是用 async 方式取得資料, 但 sync 也可以
/// 使用者，先呼叫 addEventCallbackWhenCompleted 新增 callback，再呼叫 get
public protocol IDataGetter {
    func addEventCallbackWhenCompleted(_ fn: @escaping (_ ev:DataGetterEventData?)->Void )
    func getDataAndTriggerCompletedEvent(_ addr: String,_ vers:[String])
}

public class DataGetterEventData {
    public init(_ vers: [DOneLine],_ datas: [[DOneLine]]) {
        self.vers = vers
        self.datas = datas
    }
    
    public var vers: [DOneLine]
    public var datas: [[DOneLine]]
}
/// 幫助理解 IDataGetter
/// 在還沒正式前，也可以用
/// 主要是事件也是一個很好的測試
class DataGetter01 : IDataGetter {
    typealias c = DataGetter01
    var ev = IjnEventOnce<c,DataGetterEventData>()
    var pfn : ((_ ev: DataGetterEventData?)->Void)?
    
    func addEventCallbackWhenCompleted(_ fn:  @escaping (_ ev: DataGetterEventData?)->Void) {
        ev.addCallback({ r1, r2 in
            fn(r2)
        })
    }
    
    
    func getDataAndTriggerCompletedEvent(_ addr: String, _ vers: [String]) {
        
        DispatchQueue.global().async {
            let vers = [ DTextString("新譯本").main() , DTextString("和合本").main() ]
            let datas = self.gTest(20)
            self.ev.triggerAndCleanCallback (self, DataGetterEventData(vers, datas))
        }
    }
    
    private func gTest(_ cnt:Int)-> [[DOneLine]] {
        var datas : [[DOneLine]] = [];

        for _ in 0..<cnt {
            datas.append([getTestCase(0).main(),getTestCase(1).main()])
        }
        return datas
    }
}
