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


// 舊版無法安全 clear callback
// 可能會移除到別人的 callback, 又或著沒移乾淨
public class IjnEventAdvanced<T1,T2> {
    public init(){}
    public typealias FnCallback = (_ sender: T1?,_ pData: T2?)-> Void
    // 可以作到 multimap 效果，但又維持了本來 append 的順序
    var fnCallbacks: [(key: String?, callback: FnCallback)] = []
    
    public func trigger(_ sender: T1? = nil, _ pData: T2? = nil) {
        for a1 in fnCallbacks {
            a1.callback(sender,pData)
        }
    }
    // key若是不同class視作不同，可參考 VCAudioBibleEvents 用 ObjectIdentifier
    // self.eventKey = "VCAudioBibleEvents\(ObjectIdentifier(self).hashValue)"
    public func addCallback(_ key:String? ,_ fn: @escaping FnCallback) {
        fnCallbacks.append((key, fn))
    }
    
    
    public func clearCallback(_ key: String? = nil) {
        if let key = key {
            fnCallbacks.removeAll { $0.key == key }
        } else {
            fnCallbacks.removeAll()
        }
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
typealias FnCallbackAny = (_ sender: Any?,_ pData: Any?)-> Void
typealias IjnEventAny = IjnEvent<Any,Any>
typealias IjnEventOnceAny = IjnEventOnce<Any,Any>
typealias IjnEventAdvancedAny = IjnEventAdvanced<Any,Any>
