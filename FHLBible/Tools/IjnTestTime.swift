import Foundation
/// 效率測試，時間測試。
public class IjnTestTime {
    typealias ThisTp = IjnTestTime
    public static var dts: [TimeInterval] = []
    
    public init() {
        ts = Date()
    }
    deinit {
        if te == nil {
            te = Date ()
        }
        ThisTp.dts.append(ts!.distance(to: te!))
    }
    public func start(){ ts = Date() }
    /// 若不呼叫，則是解構子時間
    public func end() { te = Date() }
    private var ts : Date?
    private var te : Date?
}

extension IjnTestTime {
    public static func getAvgMs() -> Double {
        if dts.count == 0 { return Double.nan }
        var sum = 0.0
        for a1 in dts {
            sum += a1 // TimeInterval 其是是 alias Double, 是秒
        }
        return (sum * 1000.0) / Double(dts.count)
    }
    public static func getMaxMs() -> Double {
        guard let m = dts.max() else { return Double.nan }
        return m * 1000.0
    }
    public static func getMinMs() -> Double {
        guard let m = dts.min() else { return Double.nan }
        return m * 1000.0
    }
}
extension IjnTestTime {
    /// 測時間，有時候第1個會特別久，因此開發這個作參考。
    public static func getAvgQ1toQ3() -> Double {
        
        if dts.count == 0 { return Double.nan }
        else if dts.count == 1 { return dts.first! }
        else if dts.count == 2 { return (dts[0]+dts[1]) / 2.0}
        else if dts.count == 3 { return dts.sorted()[1] }
        
        let di = 4.0 / Double(dts.count)
        let i1 = Int ( di + 0.5 )
        let i3 = Int ( di * 3 + 0.5 )
        
        
        let v2 = dts.sorted()
        var sum = 0.0
        for i in i1..<i3 + 1 {
            sum += v2[i]
        }
        sum /= Double((i3-i1+1))
        return sum
    }
}
