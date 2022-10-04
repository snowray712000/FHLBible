import Foundation
import UIKit

///// UIReadBibleController Click 的時候要用
///// 可能是點擊 <G1342> 也可能是點擊 #羅1:2-3;1
///// 直覺雖然只需要 資料部分，但想一下，若是交互參照時，還是要顯示版本，因此，還是要有 vers 的存在可能
//protocol IQueryor {
//    func queryAsync(_ dtext:DText ,_ fn: @escaping (_ dliness:[[DOneLine]]?,_ vers:[DOneLine]?)->Void )
//}
///// 正式的
//class QueryorMain : IQueryor {
//    func queryAsync(_ dtext: DText,  _ fn: @escaping ([[DOneLine]]?, [DOneLine]?) -> Void) {
//        if (dtext.refDescription != nil ){
//            /// 在之前就實作過了，於 DataGetter 中，核心就是 BibleReadDataGetter，馬上可使用
//            BibleReadDataGetter().queryAsync(["和合本"], dtext.refDescription!, { (vers,datas) in
//                fn(datas,vers)
//            })
//        } else if (dtext.sn != nil ){
//            if ( dtext.snAction == nil || dtext.snAction! == .list ) {
//                // default = 彙編
//            } else {
//                self.doDictType(dtext, fn) // 字典
//            }
//        }
//    }
//    func doDictType(_ dtext:DText ,_ fn: @escaping ([[DOneLine]]?, [DOneLine]?) -> Void){
//        let tp = dtext.snAction!
//        if (tp == .dict ){
//            // 全部，比較麻煩，先作吧
//            var re: [Int: [DText]] = [:]
//            let group = DispatchGroup()
//            
//            group.enter()
//            cbol(dtext, { data in
//                re[0] = data
//                group.leave()
//            })
//            
//            group.enter()
//            twcb(dtext, { data in
//                re[1] = data
//                group.leave()
//            })
//            
//            group.notify(queue: .main){
//                let dline = self.dtextsToDline( self.merge(re) )
//                fn([[dline]],nil)
//            }
//        } else if (tp == .twcb ){
//            twcb(dtext){ data in
//                let dline = self.dtextsToDline(data)
//                fn([[dline]], nil)
//            }
//        } else {
//            cbol(dtext){ data in
//                let dline = self.dtextsToDline(data)
//                fn([[dline]], nil)
//            }
//        }
//    }
//    func cbol(_ dtext: DText,_ fn2: @escaping (_ data:[DText])->Void ){
//        func cht() -> [DText]{
//            return [
//                DText("3588 ho {ho} 包括陰性的 he {hay}, 和中性的 to {to}"),DText(isNewLine: true),
//                DText(isNewLine: true),
//                DText("定冠詞"),DText(isNewLine: true),
//                DText(isNewLine: true),
//                DText("欽定本 - which 413, who 79, the things 11, the son 8, misc 32; 543"),DText(isNewLine: true),
//                DText(isNewLine: true),
//                DText(tpContain: "ul", children: [
//                    DText(tpContain: "li", children: [
//                        DText("1) 這, 那, "),
//                    ]),
//                    DText(tpContain: "li", children: [
//                        DText("2) 他, 她, 它"),
//                    ])
//                ])
//            ]
//        }
//        func en() -> [DText]{
//            return [
//                DText("3588 ho {ho} including the feminine he {hay},"),DText(isNewLine: true),
//                DText("     and the neuter to {to}"),DText(isNewLine: true),
//                DText(isNewLine: true),
//                DText("in all their inflections, the definite article;; article"),DText(isNewLine: true),
//                DText(isNewLine: true),
//                DText("AV - which 413, who 79, the things 11, the son 8, misc 32; 543"),DText(isNewLine: true),
//                DText(isNewLine: true),
//                DText(tpContain: "ul", children: [
//                    DText(tpContain: "li", children: [
//                        DText("1) this, that, these, etc."),
//                    ])
//                ]),
//                DText(isNewLine: true),
//                DText("Only significant renderings other than \"the\" counted"),
//            ]
//        }
//        
//        var re: [DText] = []
//        if ( dtext.snAction! == .dict){
//            re.append(contentsOf: [DText("CBOL Parsing 系統"),DText(isNewLine: true)])
//            re.append(contentsOf: cht())
//            re.append(DText(isHr: true))
//            re.append(contentsOf: [DText("CBOL Parsing System"),DText(isNewLine: true)])
//            re.append(contentsOf: en())
//        } else if (dtext.snAction! == .cbol ){
//            re.append(contentsOf: cht())
//        } else {
//            re.append(contentsOf: en())
//        }
//        fn2(re)
//    }
//    func twcb(_ dtext: DText,_ fn2: @escaping (_ data:[DText])->Void ){
//        let re: [DText] = [
//            DText("3588  ὁ, ἡ, τό 複數οἱ, αἱ, τά　冠詞"),DText(isNewLine: true),
//            DText("源自指示代名詞：「這」。因為討論冠詞的使用或省略屬於文法的範圍，本辭典只討論它用法主要特徵。由於作者對文體的看法享有充分的自由，所以很難對冠詞的用法定下明確而嚴格的規則。"),DText(isNewLine: true),
//            DText("甲、冠詞作指示名詞：「這個，那個」。"),DText(isNewLine: true),
//            DText("一、詩體的用法：τοῦ γὰρ καὶ γένος ἐσμέν 我們也是祂（字義：這一位的）所生的，"),DText("#徒17:28|", refDescription: "徒17:28", isInTitle: false), DText("。"),DText(isNewLine: true),
//            DText(isNewLine: true),
//            DText("二、ὁ μὲν…ὁ δέ「這個…那個」。複數：οἱ μὲν …οἱ δέ 「有些…另一些」，論及前面的名詞：ἐσχίσθη τὸ πλῆθος …οἱ μὲν ἦσαν σὺν τοῖς Ἰουδαίοις, οἱ δὲ σὺν τοῖς ἀποστόλοις眾人就分了黨，有附從猶太人的，有附從使徒的，"),DText("#徒14:4;17:32;28:24;林前7:7;加4:23;腓1:16,17|",refDescription: "徒14:4;17:32;28:24;林前7:7;加4:23;腓1:16,17", isInTitle: false),DText("。或沒有表達以上這種關係：τούς μὲν ἀποστόλους, τοὺς δὲ προφήτας, τοὺς δὲ εὐαγγελιστάς有使徒，有先知，有傳福音的，"),DText("#弗4:11|",refDescription: "弗4:11", isInTitle: false),DText(".....略"),DText(isNewLine: true),
//        ]
//        fn2(re)
//    }
//    func merge(_ datas: [Int:[DText]])->[DText]{
//        var re: [DText] = []
//        if ( datas[0] != nil ){
//            re.append(contentsOf: datas[0]!)
//        }
//        if (datas[1] != nil){
//            re.append(contentsOf: datas[1]!)
//        }
//        return re
//    }
//    func dtextsToDline(_ dtexts:[DText])->DOneLine{
//        return DOneLine(addresses: nil, children: dtexts, ver: nil)
//    }
//}
///// 啟22，有一個 G2222，點此，出現具有 Reference, G314, 等，作為開發使用
///// 除了 G2222 外，其它與正式一致
//class QueryorDev1 : IQueryor{
//    func queryAsync(_ dtext: DText,  _ fn: @escaping ([[DOneLine]]?, [DOneLine]?) -> Void) {
//        if (dtext.sn == "2222" ){
//            fn([getTestor()],nil)
//            return
//        }
//        
//        QueryorMain().queryAsync(dtext, fn)
//    }
//    func getTestor() -> [DOneLine] {
//        let reRef: [DText] = [
//            DText("開發用內容"),DText(isNewLine: true),
//            DText("G314", sn: "314", tp: "G", tp2: "WG"),DText(isNewLine: true),
//            DText("參照"),DText("#羅1:3;4:2", refDescription: "羅1:3;4:2", isInTitle: false),DText(isNewLine: true),
//        ]
//        let re = DOneLine(addresses: "羅1:2", children: reRef, ver: "和合本")
//        return [re]
//    }
//}
//class QueryorRef1 : IQueryor{
//
//    
//    func queryAsync(_ dtext: DText, _ fn: @escaping ([[DOneLine]]?, [DOneLine]?) -> Void) {
//        let reRef: [DText] = [
//            DText("這是，亂寫的，內容"),
//            DText("G314", sn: "314", tp: "G", tp2: "WG"),
//            DText("參照"),
//            DText("#羅1:3;4:2", refDescription: "羅1:3;4:2", isInTitle: false)
//        ]
//        let re = DOneLine(addresses: "羅1:2", children: reRef, ver: "和合本")
//        fn([[re]],nil)
//    }
//}
//class QueryorDict1 : IQueryor {
//
//    func queryAsync(_ dtext: DText, _ fn: @escaping ([[DOneLine]]?, [DOneLine]?) -> Void) {
//        let reSnDict: [DText] = [
//            DText("這是亂寫的內容"),
//            DText("源自 "), DText("<G1321>", sn: "1321", tp:"G", tp2: "WG")
//        ]
//        let re = DOneLine(addresses: nil, children: reSnDict, ver: nil)
//        fn([[re]],nil)
//    }
//}
//
///// UIReadBibleController click ，若是 click <G1342>，不確定使用者是要彙編還是字典
///// 透過這個，回傳 dtext 的 tpAction
//protocol ISnTypePicker {
//    func mainAsync(_ fn: @escaping (_ tpAction:DText.SnAction?)->Void )
//}
//class SnTypePick1 : ISnTypePicker{
//    func mainAsync(_ fn: @escaping (DText.SnAction?) -> Void) {
//        fn(.cbol)
//    }
//}
//class SnTypeViaAlertDialog : ISnTypePicker {
//    /// v: 要提供來 .present 的
//    init(_ v: UIViewController) {
//        self.v = v
//    }
//    var v:UIViewController
//    func mainAsync(_ fn: @escaping (DText.SnAction?) -> Void) {
//        let r1 = UIAlertController()
//        r1.addAction(UIAlertAction(title: "彙編", style: .default, handler: { _ in fn(.list) }))
//        r1.addAction(UIAlertAction(title: "字典", style: .default, handler: { _ in fn(.dict) }))
//        r1.addAction(UIAlertAction(title: "CBOL", style: .default, handler: { _ in fn(.cbol) }))
//        r1.addAction(UIAlertAction(title: "CBOL(En)", style: .default, handler: { _ in fn(.cbole) }))
//        r1.addAction(UIAlertAction(title: "浸宣", style: .default, handler: { _ in fn(.twcb) }))
//        r1.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in fn(nil) }))
//        v.present(r1, animated: true, completion: nil)
//    }
//}
/// 會被 ReUseAtPageController 使用，而非直接在 Page Controller 使用
//public class UIReadBibleController : UIViewController {
//    var ui = UIBibleTextRendor()
//    public var addr: String = "" {
//        willSet {
//            // print("will change addr " + addr)
//        }
//        didSet {
//            // print("addr changed to " + addr)
//            
//            let r1 = DTextString("").main()
//            r1.addresses = addr
//            ui.setTitle([r1])
//        }
//    }
//
//    public override func loadView() {
//        view = UIView()
//        view.backgroundColor = .white
//        view.addSubview(ui)
//        ui.translatesAutoresizingMaskIntoConstraints = false
//        setConstraintsLRTBMarginsGuide(ui, view)
//        
//        ui.getEventClick().addCallback( { (sendor:UIBibleTextRendor?,ev:EventUIBibleTextRendorForDTextClick?)->Void in
//            if (ev != nil){
//                if (ev!.pText != nil){
//                    print(ev!.pText!)
//                    self.doClickDText(ev!.pText!)
//                }
//            }
//            
//        })
//    }
//    /// 當 sn 被 click 時，第1步，判定此 dtext 要作什麼
//    func determineSnAction(_ dtext: DText,_ comp: @escaping (DText)->Void){
//        if ( dtext.sn != nil ){
//            let snTypePicker: ISnTypePicker = SnTypeViaAlertDialog(self) // SnTypePick1()
//            snTypePicker.mainAsync({ tp in
//                dtext.snAction = tp
//                comp(dtext)
//            })
//        } else {
//            comp(dtext)
//        }
//    }
//    func doClickDText(_ dtext: DText){
//        determineSnAction(dtext, { dtext in
//            let dataQ: IQueryor? = QueryorDev1()
//            dataQ?.queryAsync(dtext, { dliness,vers in
//                if ( dliness != nil ){
//                    let ui2 = UIReadBibleController()
//                    if (vers != nil ){ // 交互參照 時會使用到
//                        ui2.ui.setTitle(vers!)
//                    }
//                    ui2.ui.setData(dliness!)
//                    ui2.title = dtext.w!
//                    self.navigationController!.pushViewController(ui2, animated: true)
//                }
//            })
//        })
//    }
//    public func set(_ versions: [DOneLine] ,_ datas: [[DOneLine]]){
//        ui.setTitle(versions)
//        ui.setData(datas)
//    }
//}
