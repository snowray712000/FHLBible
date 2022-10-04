import Foundation

/// 開發給 page 用，基本是 3 個，交替重複使用
//public class ReUseAtPageController {
//    var uiReads = [UIReadBibleController(), UIReadBibleController(), UIReadBibleController()]
//    var idxCur = 0
//    var idxAft = -1
//    var idxBef = -1
//    
//    // var addrM = AddressManagerA()
//    public func getUICurrent() -> UIReadBibleController {
//        return uiReads[idxCur]
//    }
//    public func doWhenViewDidLoad() {
//    }
//    public func doWhenBefore() -> UIReadBibleController {
//        // 預備 左邊的 控制項
//        if idxBef == -1 {
//            idxBef = 2
//            return uiReads[idxBef]
//        }
//        if idxAft == -1 {
//            idxAft = 1
//        }
//        
//        // 目前變成 idxBefore, 所以新的用 idxAfter (因為它將要失效了)
//        // 但新的要初始，用 idxBefore 這個參數作參考
//        let rNew = uiReads[idxAft]
//        
//        // 最右邊的失效, "新的右邊"以"原本目前的"取代，目前的變成"原本左邊的"，新的左邊，使用失效的"原本idxRight"
//        let idxRightOrig = idxAft
//        idxAft = idxCur // 若下次向 Before，則這個要拿掉
//        idxCur = idxBef
//        idxBef = idxRightOrig // 若下次向 After，則這個拿掉
//        
//        return rNew
//    }
//    public func doWhenAfter() -> UIReadBibleController {
//        // 預備 右邊的 控制項
//        if idxAft == -1 {
//            idxAft = 1
//            return uiReads[idxAft]
//        }
//        
//        if idxBef == -1 { // 當再按一次 after 時，但是還沒按過 defore 就會到這
//            idxBef = 2
//        }
//        
//        // 目前變成 idxAfter, 所以新的用 idxBefore (因為它將要失效了)
//        // 但新的要初始，用 idxAfter 這個參數作參考
//        let rNew = uiReads[idxBef]
//        
//        // 下面是為了「下一次」呼叫這個時，確保正確用的
//        // "新的左邊"以"原本目前的"取代，目前的變成"原本右邊的"，新的右邊，使用失效的"原本idxLeft"
//        let idxLeftOrig = idxBef
//        idxBef = idxCur
//        idxCur = idxAft
//        idxAft = idxLeftOrig
//        
//        return rNew
//    }
//
//}
