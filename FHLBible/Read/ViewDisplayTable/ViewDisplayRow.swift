//
//  ViewDisplayTable.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/27.
//

import Foundation
import UIKit


@IBDesignable
class ViewDisplayRow : ViewFromXibBase {
    override var nibName: String { "ViewDisplayRow" }
    @IBOutlet weak var viewAddr: ViewDisplayCell!
    @IBOutlet weak var stack2: UIStackView!
    
    var onClickHeader$: IjnEvent<ViewDisplayCell,DText> = IjnEvent()
    var onClickData$: IjnEvent<ViewDisplayCell,(DText?,Int)> = IjnEvent()
    var onLongClickHeader$: IjnEvent<ViewDisplayCell,[DText]> = IjnEvent()
    var onLongClickData$: IjnEvent<ViewDisplayCell,([DText]?,Int)> = IjnEvent()
    var onSwitchChanged$: IjnEvent<ViewDisplayCell, (Bool,Int)> = IjnEvent()

    /// 若是 Header 可能要顯示 Switch
    private var _isHeaderRow: Bool = false
    /// [0]，就是 header，[1] 開始是資料 column 的 cell 。 此資訊是透過 set，真實資料是從 tableview 那裡存著。
    private var _isOnOfSwitchs: [Bool] = []
    private var _isSwitchVisible: Bool = false
    /// 一個版本，資料為 [DText]，因此，多個版本，就是二維陣子
    private var datas: [[DText]] = []
    /// 左側的資訊欄，看要放什麼。
    private var dataHeader: [DText] = []
    /// 資料的寬度比例 (實作是用 constrains multiply of stack width)
    private var ratios: [CGFloat] = []
    override func initedFromXib() {
        _isOnOfSwitchs = ijnRange(0, 20).map({ _ in false}) // 避免一開啟當掉，我就不信有人會開 20 個譯本同時
        
        updateUi()
        
        viewAddr.onClicked$.addCallback {[weak self]  sender, pData in
            self?.onClickHeader$.trigger(sender, pData)
        }
        viewAddr.onLongClicked$.addCallback {[weak self]  sender, pData in
            self?.onLongClickHeader$.trigger(sender, pData)
        }
        viewAddr.onSwitchChanged$.addCallback {[weak self] sender, pData in
            self?.onSwitchChanged$.trigger( sender,(pData!, 0) ) // [0] 是 header
        }
        
    }
    // tableview reuse 特性，這個會被反覆呼叫，這個是很關鍵的函式
    func set(_ addr:  [DText], _ data: [[DText]], _ ratios: [CGFloat],_ isSnVisible:Bool,_ isFontNameOpenHanBibleTCs:[Bool]=[],_ tpTextAlignment:[NSTextAlignment] = [],isHeaderRow:Bool,isOnOfSwitchs: [Bool],isSwitchVisible:Bool){
        let sum = ratios.reduce(0.0, +)
        self.ratios = ratios.map({$0/sum})
        
        self._isHeaderRow = isHeaderRow
        self._isOnOfSwitchs = isOnOfSwitchs
        self._isSwitchVisible = isSwitchVisible
        self.datas = data
        self.dataHeader = addr
        self._isSnVisible = isSnVisible
        self._isFontNameOpenHanBibleTCs = isFontNameOpenHanBibleTCs
        self._tpTextAlignment = tpTextAlignment
        self.updateUi()
    }
    var _isSnVisible:Bool! = true // 預設值是為了 initedFromXib
    
    /**
     - 為了要給 cell 繪圖時，知道是台語版本，就可以使用字型。
     - [i] 的 i 是指 data 的 col ， 不包含 header。即 [0] 是第1個版本有沒有台語
     - header 直接傳 false
     */
    private var _isFontNameOpenHanBibleTCs: [Bool] = []
    
    ///  靠右對齊 (舊約會用到)
    private var _tpTextAlignment: [NSTextAlignment] = []
    
    /**
     避免太多參數，包成函數
     - Parameters:
        - cellview: ViewDisplayCell 本體，這裡就是使用它的 .set
        - data: cell資料內容，[DText] 型態，就是一串文字。
        - colOfTable: [0] 當然表示 header, [1] 就是 data 的第 [0] 個。
        - isFontNameOpenHanBibleTC: 只有 header col 才會用到，傳入 false，其它 col 會用參數 col
        - tpTextAlignment: header col 才會用到，用 .center 吧。
     */
    private func _set_cellview(cellview: ViewDisplayCell, data:[DText], colOfTable:Int, isFontNameOpenHanBibleTC: Bool? = nil, tpTextAlignment: NSTextAlignment? = nil){
        assert ( colOfTable != 0 || (colOfTable==0 && isFontNameOpenHanBibleTC != nil && tpTextAlignment != nil))
        
        let isHanTC = isFontNameOpenHanBibleTC != nil ? isFontNameOpenHanBibleTC! : _isFontNameOpenHanBibleTCs[colOfTable-1]
        let tpAlign = tpTextAlignment != nil ? tpTextAlignment! : _tpTextAlignment[colOfTable-1]
        
        cellview.set(dtexts: data, isVisibleSn: _isSnVisible, isFontNameOpenHanBibleTC: isHanTC, tpTextAlignment: tpAlign, isSwitchOn: _isOnOfSwitchs[colOfTable], isSwitchVisible: _isSwitchVisible)
    }
    private func updateUi(){
        // 標題 "創1:1" 置中
        _set_cellview(cellview: viewAddr, data: dataHeader, colOfTable: 0, isFontNameOpenHanBibleTC:  false, tpTextAlignment: .center)
        
        stack2.arrangedSubviews.forEach({$0.removeFromSuperview()})
        
        for i in 0..<datas.count {
            // 提示: i, 是同一節，不同譯本，不是每版本，不同節唷。
            
            let re1 = ViewDisplayCell()
            re1.onClicked$.addCallback {[weak self] sender, pData in
                self?.onClickData$.trigger(sender, (pData,i))
            }
            re1.onLongClicked$.addCallback {[weak self] sender, pData in
                self?.onLongClickData$.trigger(sender, (pData,i))
            }
            re1.onSwitchChanged$.addCallback {[weak self] sender, pData in
                self?.onSwitchChanged$.trigger( sender,(pData!, i + 1) ) // [0] 是 header
            }
            
            stack2.addArrangedSubview(re1)
            re1.widthAnchor.constraint(equalTo: stack2.widthAnchor, multiplier: self.ratios[i]).isActive = true
            
            _set_cellview(cellview: re1, data: datas[i], colOfTable: i+1)
        }
    }
    
}
