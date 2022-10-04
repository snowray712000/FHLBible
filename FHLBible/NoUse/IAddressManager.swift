import Foundation


/// ReadPageController 時用到
//public protocol IAddressManager {
//    /// view did load 時, 會問 "上次是看到哪段經文"
//    func getCurrentAddress() -> String
//    /// page controller 拉動，要顯示右邊的 view controller 時，要計算，(若中間是 addrRef, 那右邊會是哪段經文呢)
//    /// 例如， addrRef 創2，就要回 創3；啟22，就要回 nil
//    func getAddressAfter(_ addrRef: String) -> String?
//    /// page controller 拉動，要顯示右邊的 view controller 時，要計算，(若中間是 addrRef, 那右邊會是哪段經文呢)
//    /// - Parameter addrRef: 若 addrRef 是創2，就回傳 創1；若是 創1，就回傳 nil
//    func getAddressBefore(_ addrRef: String) -> String?
//}

///// 在 ReadPageController 時用到
//public class AddressM : IAddressManager {
//    /// G: global A: Address M: Manager C: Core
//    typealias GAMC = AddressManagerCore
//    
//    public func getCurrentAddress() -> String {
//        guard let r1 = GAMC.s.getCurrentVerse() else { return "啟22"}
//        return VerseRangeToString().main(r1.verses)
//    }
//    
//    public func getAddressAfter(_ addrRef: String) -> String? {
//        return BibleGetNextOrPrevChap.getNextChapInStr(addrRef)
//    }
//    
//    public func getAddressBefore(_ addrRef: String) -> String? {
//        return BibleGetNextOrPrevChap.getPrevChapInStr(addrRef)
//    }
//}

/// AddressM 樣本
//public class AddressManagerA : IAddressManager {
//    public func getCurrentAddress() -> String {
//        return "創2"
//    }
//    public func getAddressAfter(_ addrRef: String) -> String? {
//        return "創3"
//    }
//    public func getAddressBefore(_ addrRef: String) -> String? {
//        return "創1"
//    }
//}
