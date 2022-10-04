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

    /// 一個版本，資料為 [DText]，因此，多個版本，就是二維陣子
    private var datas: [[DText]] = []
    /// 左側的資訊欄，看要放什麼。
    private var dataHeader: [DText] = []
    /// 資料的寬度比例 (實作是用 constrains multiply of stack width)
    private var ratios: [CGFloat] = []
    override func initedFromXib() {
        updateUi()
        
        viewAddr.onClicked$.addCallback { sender, pData in
            self.onClickHeader$.trigger(sender, pData)
        }
    }
    func set(_ addr:  [DText], _ data: [[DText]], _ ratios: [CGFloat],_ isSnVisible:Bool,_ isFontNameOpenHanBibleTCs:[Bool]=[],_ tpTextAlignment:[NSTextAlignment] = [] ){
        let sum = ratios.reduce(0.0, +)
        self.ratios = ratios.map({$0/sum})
        
        self.datas = data
        self.dataHeader = addr
        self._isSnVisible = isSnVisible
        self._isFontNameOpenHanBibleTCs = isFontNameOpenHanBibleTCs
        self._tpTextAlignment = tpTextAlignment
        self.updateUi()
    }
    var _isSnVisible:Bool! = true // 預設值是為了 initedFromXib
    /// 為了要給 cell 繪圖時，知道是台語版本，就可以使用字型。
    private var _isFontNameOpenHanBibleTCs: [Bool] = []
    /// 靠右對齊 (舊約會用到)
    private var _tpTextAlignment: [NSTextAlignment] = []
    
    private func updateUi(){
        viewAddr.set(dataHeader, _isSnVisible, false, .center) // 標題 "創1:1" 置中
        
        stack2.arrangedSubviews.forEach({$0.removeFromSuperview()})
        
        for i in 0..<datas.count {
            let re1 = ViewDisplayCell()
            re1.onClicked$.addCallback { sender, pData in
                self.onClickData$.trigger(sender, (pData,i))
            }
            
            stack2.addArrangedSubview(re1)
            re1.widthAnchor.constraint(equalTo: stack2.widthAnchor, multiplier: self.ratios[i]).isActive = true
            
            re1.set(datas[i],_isSnVisible, _isFontNameOpenHanBibleTCs[i], _tpTextAlignment[i] )
        }
    }
    
}
