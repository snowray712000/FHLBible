/**
 
 */

import Foundation
import UIKit


class DOneLongPressCellSetting {
    /** 傳入此，就必須傳入 viewController */
    var strHelp: String?
    var strDoSomething: String?
    /** 其實是與 switch 合作，因為 switch 不能顯示描述 */
    var strLabel: String?
    
    /** 供 help 用的, 因為要 present */
    weak var viewController: UIViewController?
    
    /** 若放在 cell 中，因為會 reuse ， 所以每次都要重新 bind 就會比較麻煩，而與資料放在一起，就可以 bind 一次即可 */
    var evDo: IjnEventAny = IjnEventAny()
    /** 需要 bool 作為 data，所以不使用 Any */
    var evSwitch1 = IjnEvent<LongPressFuncCell, Bool>()
    
    typealias FnBoolOptional = ()->Bool
    /** Switch 選項，需要能傳入初始化資料，在  reuse set cell 時，就是使用這個 */
    var fnIsOnSwitch: FnBoolOptional?
    
    init(strHelp: String? = nil, strDoSomething: String? = nil, strLabel: String? = nil, viewController: UIViewController? = nil) {
        self.strHelp = strHelp
        self.strDoSomething = strDoSomething
        self.strLabel = strLabel
        self.viewController = viewController
        
        if strHelp != nil {
            assert ( viewController != nil )
        }
    }
}
