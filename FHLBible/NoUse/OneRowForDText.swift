import Foundation
import UIKit

/// 同一節，但不同版本。
//public class OneRowForDText : UIStackView {
//    /// 重複使用的
//    var views: [IjnDTextTextView] = []
//    var viewLeft = IjnDTextTextView()
//    var stackViewLeft = UIStackView()
//    var stackViewRight = UIStackView()
//    var cntVersionLast = 0
//    private var eventClickOneCol: IjnEvent<OneRowForDText,EventOneRowForDTextClick> = IjnEvent()
//    public func getEventEventOneRowForDTextClick() -> IjnEvent<OneRowForDText,EventOneRowForDTextClick> {
//        return eventClickOneCol
//    }
//    /// 當「字典」結果顯示，章節欄不需要，不要是「空白」(佔空間)，而是隱藏起來
//    /// 當顯示「經文」時，章節欄就要打開
//    /// 這是供 parent 決定，因為這個 class 只是「其中一列」，它不知道，是不是「所有資料列」的 address 都是 nil
//    public func setLeftVisible(_ isVisible:Bool){
//        self.stackViewLeft.isHidden = !isVisible
//    }
//    
//    private func doOneColEvent( _ sender: UITextView?,_ ev: EventDTextClick?,_ idxCol: Int){
//        let re = EventOneRowForDTextClick()
//        
//        re.gs = ev?.gs
//        re.pLine = ev?.pLine
//        re.idxChar = ev?.idxChar
//        re.pText = ev?.pText
//        
//        re.pSendorTextView = sender
//        re.idxCol = idxCol
//        
//        eventClickOneCol.trigger(self, re)
//    }
//    public func set(_ data: [DOneLine]){
//        // assert(data.count != 0)
//        if data.count == 0 {
//            // isHidden = true
////            changeVisible(0)
////            viewLeft.setData(DTextString("").main())
////            setNeedsLayout()
//            return
//        }
//        
//        // 初始化一定有的 stackLeft Right viewLeft
//        if views.count == 0 {
//            initial()
//        }
//        
//        // 重複用的不夠
//        if views.count < data.count {
//            initialViews(data.count)
//        }
//        
//        /// 多 或 少 都要去把某些 show 或 把某些 hide
//        if cntVersionLast != data.count {
//            changeVisible(data.count)
//        }
//        
//        viewLeft.setData(DTextString(getAddress(data)).main())
//        
//        for i in 0..<data.count {
//            views[i].setData(data[i])
//        }
//        cntVersionLast = data.count
//        
//    }
//    private func getAddress(_ data:[DOneLine]) -> String{
//        return data[0].addresses ?? ""
//    }
//    private func changeVisible(_ cntNeed: Int){
//        if cntVersionLast < cntNeed {
//            for i in cntVersionLast..<cntNeed {
//                views[i].isHidden = false
//            }
//        } else {
//            for i in cntNeed..<cntVersionLast {
//                views[i].isHidden = true
//            }
//        }
//    }
//    private func initialViews(_ cntNeed:Int){
//        let cntView = views.count
//        for i in cntView..<cntNeed {
//            let r1 = IjnDTextTextView()
//            r1.setInterfaceDText2AttributeString(DTextConvertBase())
//            r1.getEventDTextClick().addCallback({(a1,a2) in
//                if a2 != nil {
//                    if a2!.pText != nil {
//                        self.doOneColEvent(a1, a2, i)
//                    }
//                }
//            });
//            
//            r1.isHidden = true // 初次 cntVersionLast 是 0
//            views.append(r1)
//            stackViewRight.addArrangedSubview(r1)
//        }
//    }
//
//    private func initial(){
//        axis = .horizontal
//        distribution = .fill
//        
//        initial_left()
//
//        initial_right()
//    }
//    private func initial_right(){
//        stackViewRight.axis = .horizontal
//        stackViewRight.distribution = .fillEqually
//        addArrangedSubview(stackViewRight)
//    }
//    private func initial_left(){
//        addArrangedSubview(stackViewLeft)
//        stackViewLeft.axis = .horizontal // 其實目前沒差
//        stackViewLeft.addArrangedSubview(viewLeft)
//        
//        stackViewLeft.translatesAutoresizingMaskIntoConstraints = false // 只要有 constrain 這就是必需的
//        stackViewLeft.widthAnchor.constraint(equalToConstant: 40).isActive = true
//        
////        stackViewLeft.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
//        
//        viewLeft.setInterfaceDText2AttributeString(DTextConvertBase())
//        viewLeft.getEventDTextClick().addCallback({(a1,a2) in
//            if a2 != nil {
//                if a2!.pText != nil {
//                    self.doOneColEvent(a1, a2, -1)
//                }
//            }
//        });
//    }
//}
