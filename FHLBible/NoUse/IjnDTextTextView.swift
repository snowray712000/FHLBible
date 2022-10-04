
import Foundation
import UIKit


/// C: class Clickable TextView
//public protocol CClickableTextView {
//    func getEventClickGetCharIdx() -> IjnEvent<UITextView,EventCharIdx>
//}
///// 最終產品是 IjnDTextTextView，
///// 符合 CClickableTextView
//open class IjnClickTextView : UITextView, CClickableTextView {
//
//    public static func generateToInterface() -> CClickableTextView {
//        let re : CClickableTextView = IjnClickTextView()
//        return re
//    }
//    public func getEventClickGetCharIdx() -> IjnEvent<UITextView, EventCharIdx> {
//        return eventClickGetCharIdx
//    }
//
//    public override init(frame: CGRect, textContainer: NSTextContainer?) {
//        super.init(frame: frame, textContainer: textContainer)
//
//        initApperance()
//        addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(tapOnce)))
//    }
//    public required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
//    private func initApperance(){
//        isScrollEnabled = false
//        isSelectable = false
//        isEditable = false
//        textAlignment = .justified
//        translatesAutoresizingMaskIntoConstraints = false
//    }
//
//    private var eventClickGetCharIdx: IjnEvent<UITextView,EventCharIdx> = IjnEvent()
//    @objc func tapOnce(_ gs: UITapGestureRecognizer){
//        let idxChar = DetermineWhichCharClicked().MainForTextview(gs.location(in: self), self)
//        let ev = EventCharIdx()
//        ev.gs = gs
//        ev.idxChar = idxChar
//        eventClickGetCharIdx.trigger(self, ev)
//    }
//}
//
//public protocol CIjnDTextTextView {
//    func getEventDTextClick()-> IjnEvent<UITextView,EventDTextClick>
//    /// 注意，要在 setData 之前設定。
//    func setInterfaceDText2AttributeString(_ iCvt: IDTextToAttributeString?)
//    func setData(_ data: DOneLine)
//}
//public protocol IDTextToAttributeString{
//    func converting(_ texts: [DText]) -> [NSMutableAttributedString]
//}

/// 主要是 OneRowForDText 會使用它
//open class IjnDTextTextView : IjnClickTextView, CIjnDTextTextView, IDTextToAttributeString {
//    public func setInterfaceDText2AttributeString(_ iCvt: IDTextToAttributeString?) {
//        self.idtext2attrString = iCvt
//    }
//    public func getEventDTextClick() -> IjnEvent<UITextView, EventDTextClick> {
//        return eventClickGetDText
//    }
//    public func setData(_ data: DOneLine){
//        self.data = data
//
//        let re = NSMutableAttributedString()
//        dataToAttributeText().forEach({re.append($0)})
//        attributedText = re
//    }
//
//    /// 此將會被 interface 取代
//    public func converting(_ texts: [DText]) -> [NSMutableAttributedString] {
//        var re: [NSMutableAttributedString] = []
//        for a1 in texts {
//            re.append ( NSMutableAttributedString(string: a1.w!, attributes: [NSAttributedString.Key.foregroundColor : UIColor.red] ) )
//        }
//        return re
//    }
//
//    private var data : DOneLine?
//    /// 注意，要在 setData 前設定唷
//    public var idtext2attrString: IDTextToAttributeString? = nil
//    private var eventClickGetDText: IjnEvent<UITextView,EventDTextClick> = IjnEvent()
//
//    public required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
//    public override init(frame: CGRect, textContainer: NSTextContainer?) {
//        super.init(frame: frame, textContainer: textContainer)
//        super.getEventClickGetCharIdx().addCallback(doCharIdx)
//    }
//
//    /// 將事件 charidx 轉 GetDText (從 charIdx 得到是第幾個 dtext 是關鍵)
//    private func doCharIdx(_ sender: UITextView?,_ ev: EventCharIdx?){
//        let re = EventDTextClick()
//
//        re.gs = ev?.gs
//        re.idxChar = ev?.idxChar
//        re.pLine = self.data
//
//        if ev != nil && ev!.idxChar != nil {
//            re.pText = getDText(ev!.idxChar!)
//        }
//        eventClickGetDText.trigger(self, re)
//    }
//
//
//    /// 使用於 doCharIdx 使用在 click 之後，得到 idxChar，然後看看是哪個 DText 的。
//    private func getDText(_ idxChar: Int)-> DText? {
//        if idxChar == -1 { return nil }
//
//        guard let data = data else { return nil }
//        guard let texts = data.children else { return nil }
//        if idxChar == 0 { return texts[0] }
//
//        var sum = 0
//        for a1 in texts {
//            sum += a1.w != nil ? a1.w!.count : 0
//            if ( sum > idxChar ) { return a1}
//        }
//
//        return texts.last!
//    }
//
//    // call by setData
//    private func dataToAttributeText() -> [NSMutableAttributedString] {
//        guard let data = self.data else { return [] }
//        guard let texts = data.children else {return [] }
//        let iCvt = self.idtext2attrString ?? self
//        return iCvt.converting(texts)
//    }
//}
//public class EventCharIdx : NSObject {
//    public override init (){ super.init() }
//    public var idxChar : Int?
//    public var gs: UITapGestureRecognizer?
//}
//
//public class EventDTextClick : EventCharIdx {
//    public override init(){ super.init() }
//    public var pLine : DOneLine?
//    public var pText : DText?
//}
///// 供 DTextView Click 使用
//internal class DetermineWhichCharClicked {
//    public func MainForTextview(_ xyTap: CGPoint,_ v: UITextView) -> Int {
//
//        var xy = xyTap
//        xy.x -= v.textContainerInset.left
//        xy.y -= v.textContainerInset.top
//
//        if isNotInFirstAndEndCharacter(xy, v) {
//            return -1
//        }
//
//        let m = v.layoutManager
//        return m.characterIndex(for: xy, in: v.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
//    }
//    private func isNotInFirstAndEndCharacter(_ p: CGPoint,_ v: UITextView) -> Bool {
//        let m = v.layoutManager
//        let texts = m.textStorage!.length
//        let rr1 = m.boundingRect(forGlyphRange: NSRange(location: 0, length: 1), in: m.textContainers[0]) // {5,0}
//        let rr2 = m.boundingRect(forGlyphRange: NSRange(location: texts-1, length: 1), in: m.textContainers[0]) // {231,46}
//
//
//        if p.x < rr1.minX || p.y < rr1.minY {
//            return true // not in
//        }
//        if p.y > rr2.maxY {
//            return true // not in
//        }
//
//        if  rr2.minY <= p.y && p.y <= rr2.maxY  {
//            if p.x > rr2.maxX {
//                return true
//            }
//        }
//
//        return false
//    }
//}
