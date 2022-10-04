import UIKit
import Combine

/// T1，通常是 sendor 型態。T2通常是資料型態
/// 觸發者，用 trigger
public class IjnEvent<T1,T2> {
    public init(){}
    public typealias FnCallback = (_ sender: T1?,_ pData: T2?)-> Void
    internal var fnCallbacks: [FnCallback] = []
    
    public func trigger(_ sender: T1? = nil, _ pData: T2? = nil){
        for a1 in fnCallbacks {
            a1(sender,pData)
        }
    }
    public func addCallback(_ fn: @escaping FnCallback){
        fnCallbacks.append(fn)
    }
    public func clearCallback(){
        fnCallbacks.removeAll()
    }
}


/// T1，通常是 sendor 型態。T2通常是資料型態
/// 呼叫完 fn，然後就自動將 callbacks 清空
public class IjnEventOnce<T1,T2> {
    public typealias FnCallback = (_ sender: T1?,_ pData: T2?)-> Void
    private var fnCallbacks: [FnCallback] = []
    
    public init(){}
    public func triggerAndCleanCallback(_ sender: T1? = nil, _ pData: T2? = nil){
        for a1 in fnCallbacks {
            a1(sender,pData)
        }
        fnCallbacks.removeAll()
    }
    public func addCallback(_ fn: @escaping FnCallback){
        fnCallbacks.append(fn)
    }
}

typealias IjnEventAny = IjnEvent<Any,Any>
typealias IjnEventOnceAny = IjnEventOnce<Any,Any>
