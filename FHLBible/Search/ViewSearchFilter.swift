//
//  ViewSearchResult.swift
//  FHLBible
//
//  Created by littlesnow on 2021/10/23.
//

import UIKit

@IBDesignable
class ViewSearchFilter: ViewFromXibBase {
    /// filters 統計資料, opt 目前選哪個, group 目前是 "書卷" 還是 "分類"
    /// 當傳 nil 時，表示正準備開始搜尋中
    func setInitData(_ filters: [SearchData.Filter]?, _ opt: String?,_ group: String?){
        self.curOpt = opt
        self.curGroup = group
        self.filters = filters
        
        self.drawBtns()
    }
    
    var onClickFilterOption$: IjnEvent<UIButton, SearchData.Filter> = IjnEvent()
    
    override var nibName: String { "ViewSearchFilter" }
    @IBOutlet weak var viewScroll : UIScrollView!
    @IBOutlet weak var viewStack : UIStackView!
    @IBOutlet weak var btnGroup : UIButton!
    @IBOutlet weak var btnTemplate : UIButton!
    
    override func initedFromXib() {
        btnGroup.translatesAutoresizingMaskIntoConstraints = false
        btnGroup.frame.size = intrinsicContentSize
        btnTemplate.isHidden = true
    }
    
    var filters: [SearchData.Filter]? = []
    var curGroup: String? = "分類"
    var curOpt: String? = ""
    // 方便使用，全部還原按鈕 selected 與 原色
    var btns: [UIButton] = []
    func resetBtnsNonSelected(){
        btns.forEach({$0.isSelected=false})
    }
    
    func drawBtns(){
        viewStack.arrangedSubviews.forEach({$0.removeFromSuperview()})
        if filters != nil {
            let btns = filters!.filter({$0.na2==curGroup}).map({gBtn($0)})
            btns.forEach({viewStack.addArrangedSubview($0)})
            
            self.btns = btns
        }
        
    }
    func gBtn(_ filter: SearchData.Filter) -> UIButton {
        let re = UIButton()
        cloneStyle(re)
        
        re.setTitle(filter.w, for: .normal)
        re.frame.size = re.intrinsicContentSize
        re.translatesAutoresizingMaskIntoConstraints = false
        
        if (filter.na == curOpt){
            re.setTitleColor(.label, for: .selected)
            re.isSelected = true
        }
        
        re.addAction(UIAction(handler: { a1 in
            
            self.resetBtnsNonSelected()
            self.curOpt = filter.na
            let ui = a1.sender as! UIButton
            ui.isSelected = true
            ui.setTitleColor(.label, for: .selected)
            
            self.onClickFilterOption$.trigger(ui, filter)
            
        }), for: .primaryActionTriggered)
        
        
        return re
    }
    func cloneStyle(_ btn: UIButton){
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.layer.cornerRadius = 5.0
        btn.contentEdgeInsets.left = 3.0
        btn.contentEdgeInsets.right = 3.0
        btn.contentEdgeInsets.top = 3.0
        btn.contentEdgeInsets.bottom = 3.0
        
    }

    @IBAction func clickGroupChange(){
        if curGroup == "分類" {
            curGroup = "書卷"
        } else {
            curGroup = "分類"
        }
        
        btnGroup.setTitle(curGroup, for: .normal)
        drawBtns()
    }
    
}
