import Foundation
/// IDataGetter 用在 UIReadPageController
class DataGetterUsingBibleReader : IDataGetter {
    typealias c = DataGetterUsingBibleReader
    var ev = IjnEventOnce<c,DataGetterEventData>()
    var pfn : ((_ ev: DataGetterEventData?)->Void)?
    
    func addEventCallbackWhenCompleted(_ fn:  @escaping (_ ev: DataGetterEventData?)->Void) {
        ev.addCallback({ r1, r2 in
            fn(r2)
        })
    }
    func getDataAndTriggerCompletedEvent(_ addr: String, _ vers: [String]) {
        
        BibleReadDataGetter().queryAsync(vers, addr, { vers, datas in
            self.ev.triggerAndCleanCallback (self, DataGetterEventData(vers, datas))
        })
    }
}

