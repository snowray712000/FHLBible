import Foundation
import UIKit

//public class UIBibleTextRendor : UIScrollView {
//    /// 初始化在 initStv() , initOnce()
//    var stv = UIStackView()
//    var rowTitle = OneRowForDText()
//    var rowDatas: [OneRowForDText] = []
//    var cntVisible = 0
//    /// 保護 initOnce 被呼叫2次
//    var isInitialAlready = false
//    
//    private var eventClick: IjnEvent<UIBibleTextRendor,EventUIBibleTextRendorForDTextClick> = IjnEvent()
//    public func getEventClick() -> IjnEvent<UIBibleTextRendor,EventUIBibleTextRendorForDTextClick> {
//        return eventClick
//    }
//    
//    public func setTitle(_ strs:[DOneLine]){
//        initOnce()
//        
//        rowTitle.set(strs)
//    }
//    public func setData(_ strs:[[DOneLine]]){
//        initOnce()
//        
//        if rowDatas.count < strs.count {
//            let r1 = rowDatas.count
//            for i in r1..<strs.count {
//                let r2 = OneRowForDText()
//                stv.addArrangedSubview(r2)
//                rowDatas.append(r2)
//                setCallbackClick_whenGenerateRow(i, r2)
//            }
//        }
//        if cntVisible != strs.count {
//            if cntVisible < strs.count {
//                for i in cntVisible..<strs.count {
//                    rowDatas[i].isHidden = false
//                }
//            } else {
//                for i in strs.count..<cntVisible {
//                    rowDatas[i].isHidden = true
//                }
//            }
//        }
//        cntVisible = strs.count
//        
//        let isNoAddress = isAllAddressNil(strs)
//        for i in 0..<strs.count {
//            rowDatas[i].set(strs[i])
//            rowDatas[i].setLeftVisible(false == isNoAddress)
//        }
//    }
//    /// 當此 ui 是用在 顯示字典時，就只會有 dtexts 而不會有 address
//    /// 多個版本時， addresses 都看第1個版本，所以程式只檢查 [0]
//    private func isAllAddressNil(_ strs:[[DOneLine]])->Bool{
//        for a1 in strs {
//            if ( a1.count != 0 && a1[0].addresses != nil ){
//                return false
//            }
//        }
//        return true
//    }
//    private func initOnce(){
//        if isInitialAlready {
//            return
//        }
//        
//        initStv()
//        initTitleRow()
//        isInitialAlready = true
//    }
//    private func initTitleRow(){
//        stv.addArrangedSubview(rowTitle)
//        setCallbackClick_whenGenerateRow(-1, rowTitle)
//    }
//    private func initStv(){
//        addSubview(stv)
//        setConstraintsLRTB(stv, self)
//        stv.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
//        stv.translatesAutoresizingMaskIntoConstraints = false
//        stv.axis = .vertical
//    }
//    
//    
//    private func setCallbackClick_whenGenerateRow(_ idx: Int, _ row: OneRowForDText){
//        
//        row.getEventEventOneRowForDTextClick().addCallback({ [self] (a1,a2) in
//
//            let re = EventUIBibleTextRendorForDTextClick()
//            
//            re.gs = a2?.gs
//            re.pLine = a2?.pLine
//            re.idxChar = a2?.idxCol
//            re.pText = a2?.pText
//            
//            re.pSendorTextView = a2?.pSendorTextView
//            re.idxCol = a2?.idxCol
//            
//            re.idxRow = idx
//            
//            self.eventClick.trigger(self, re)
//        });
//    }
//}
